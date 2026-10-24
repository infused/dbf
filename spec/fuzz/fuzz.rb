# frozen_string_literal: true

# Coverage-guided mutation fuzzer for the DBF read path.
#
# Mutates the .dbf/.dbc and memo (.dbt/.fpt/.dct) fixtures under
# spec/fixtures and feeds each pair through DBF::Table.new(StringIO,
# StringIO), #columns, #each (with #to_a, #attributes and #[]), #record,
# #schema in every format and #to_csv. An input is reported when it
#
#   * raises anything that is not a DBF::Error (crash),
#   * runs longer than --budget seconds (slow) or hits the hard limit (hang),
#   * allocates more than --alloc-ratio times its own size (plus the memo
#     bytes it was served) plus --alloc-floor bytes (alloc).
#
# Many records can point at the same memo block, so work grows with
# records x memo size. That amplification is inherent to the format and
# documented in the README, so an input that is served more than
# MEMO_FANOUT times its memo file (plus 1 MiB) is stopped and counted as
# "fanout" rather than reported.
#
# Each finding is minimised and written to --out as <kind>-<id>.dbf,
# <kind>-<id>.memo (when a memo is involved) and <kind>-<id>.txt (signature,
# backtrace and a reproducer). Findings whose signature is already in --out
# are not reported again, so delete the directory to start afresh.
#
# Inputs that reach new branches are kept in --out/corpus. Parallel workers
# (--jobs) share them while they run, and a later run with the same --out
# starts from them.
#
# The fuzzer is not part of the rspec run. Usage:
#
#   bundle exec rake fuzz                        # FUZZ_TIME, FUZZ_JOBS, FUZZ_SEED
#   ruby spec/fuzz/fuzz.rb --time 600 --jobs 4
#   ruby spec/fuzz/fuzz.rb --repro tmp/fuzz/crash-0123456789.dbf [memo]
#
# Exits non-zero when it reports a finding.

require 'coverage'
require 'csv'
require 'date'
require 'digest'
require 'fileutils'
require 'forwardable'
require 'json'
require 'optparse'
require 'stringio'
require 'time'
require 'timeout'

# Measure branch coverage of the library only: everything it depends on is
# loaded above, before coverage starts.
Coverage.setup(branches: true)
Coverage.resume
$LOAD_PATH.unshift File.expand_path('../../lib', __dir__)
require 'dbf'

module DBFFuzz
  ROOT = File.expand_path('../..', __dir__)
  LIB = File.join(ROOT, 'lib', '')
  FIXTURES = File.join(ROOT, 'spec', 'fixtures')

  DATA_EXTENSIONS = %w[.dbf .dbc].freeze
  MEMO_EXTENSIONS = %w[.dbt .fpt .dct].freeze

  # Seeds larger than this are cut down to whole records so a single
  # iteration stays fast.
  MAX_SEED_SIZE = 64 * 1024
  # Twice the largest seed, small enough that linear per-record work stays
  # well inside the time budget even on a loaded machine.
  MAX_INPUT_SIZE = 128 * 1024
  MAX_CORPUS = 4096
  MEMO_FANOUT = 4

  Finding = Struct.new(:kind, :signature, :error, :elapsed, :allocated, :step, keyword_init: true)
  Input = Struct.new(:dbf, :memo) do
    def size = dbf.bytesize + memo.to_s.bytesize
  end

  # Counts the memo bytes handed out during a run and stops the run once
  # they exceed the fan-out limit.
  module MemoMeter
    class << self
      attr_accessor :served, :limit
    end

    def get(start_block)
      super.tap do |memo|
        MemoMeter.served += memo.bytesize if memo
        throw MemoMeter if MemoMeter.served > MemoMeter.limit
      end
    end
  end
  DBF::Memo::Base.prepend(MemoMeter)

  # Runs one input through the read path and classifies the outcome.
  class Target
    def initialize(budget:, alloc_ratio:, alloc_floor:, hard_limit:)
      @budget = budget
      @alloc_ratio = alloc_ratio
      @alloc_floor = alloc_floor
      @hard_limit = hard_limit
    end

    # @return [Finding, nil] nil when nothing is wrong; a :fanout finding is
    #   the known memo amplification, not a bug
    def run(input)
      @step_costs = {}
      MemoMeter.served = 0
      MemoMeter.limit = (MEMO_FANOUT * input.memo.to_s.bytesize) + (1024 * 1024)
      result = Finding.new(kind: :fanout, signature: 'fanout')
      catch(MemoMeter) do
        error, elapsed, allocated = measure { exercise(input) }
        result = classify(input, error, elapsed, allocated)
      end
      result
    end

    # Runs the steps outside #measure, so a crash propagates with its full
    # backtrace.
    def replay(input)
      @step_costs = {}
      MemoMeter.served = 0
      MemoMeter.limit = Float::INFINITY
      exercise(input)
    end

    private

    def classify(input, error, elapsed, allocated)
      attrs = {error:, elapsed:, allocated:}
      if error.is_a?(Timeout::Error)
        Finding.new(kind: :hang, signature: "hang:#{@current_step}", step: @current_step, **attrs)
      elsif error
        Finding.new(kind: :crash, signature: crash_signature(error), step: @current_step, **attrs)
      elsif elapsed > @budget
        step = costliest(0)
        Finding.new(kind: :slow, signature: "slow:#{step}", step:, **attrs)
      elsif allocated > ((input.size + MemoMeter.served) * @alloc_ratio) + @alloc_floor
        step = costliest(1)
        Finding.new(kind: :alloc, signature: "alloc:#{step}", step:, **attrs)
      end
    end

    def costliest(index)
      @step_costs.max_by { |_step, costs| costs[index] }&.first
    end

    def crash_signature(error)
      frame = error.backtrace&.find { |line| line.start_with?(LIB) } || error.backtrace&.first
      "#{error.class}@#{frame.to_s.delete_prefix(ROOT).sub(/:in .*/, '')}"
    end

    def measure(&)
      error = nil
      GC.disable
      started = now
      before = allocated_bytes
      begin
        Timeout.timeout(@hard_limit, &)
      rescue Exception => e # rubocop:disable Lint/RescueException
        raise if e.is_a?(SignalException) || e.is_a?(SystemExit)

        error = e
      end
      [error, now - started, allocated_bytes - before]
    ensure
      GC.enable
    end

    def exercise(input)
      table = nil
      step(:open) { table = DBF::Table.new(StringIO.new(input.dbf), input.memo && StringIO.new(input.memo), name: 'fuzz') }
      return unless table

      step(:columns) { table.columns }
      step(:each) { table.each { |record| read_record(record) } }
      step(:record) { record_indexes(table).each { |index| read_record(table.record(index)) } }
      step(:schema_activerecord) { table.schema(:activerecord) }
      step(:schema_sequel) { table.schema(:sequel) }
      step(:schema_json) { table.schema(:json) }
      step(:to_csv) { table.to_csv(StringIO.new) }
    end

    def record_indexes(table)
      count = table.record_count
      [0, 1, count / 2, count - 1, count, -1].uniq
    end

    def read_record(record)
      return unless record

      # #[] decodes a single column before the record is materialised
      name = record.send(:column_names).first
      record[name] if name
      record.to_a
      record.attributes
    end

    # A DBF::Error is the documented failure mode, so it only ends the step.
    def step(name)
      @current_step = name
      started = now
      before = allocated_bytes
      begin
        yield
      rescue DBF::Error
        nil
      end
      @step_costs[name] = [now - started, allocated_bytes - before]
    end

    def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)

    # Bytes allocated so far: object slots plus malloc'd buffers. With GC
    # disabled nothing is freed, so the difference across a run is what the
    # run allocated.
    def allocated_bytes
      slots = GC.stat_heap.sum { |_heap, stat| stat[:slot_size] * stat[:total_allocated_objects] }
      slots + GC.stat(:malloc_increase_bytes)
    end
  end

  # Byte-level mutations, biased towards the fields the parser trusts.
  class Mutator
    INTERESTING_BYTES = [
      0x00, 0x01, 0x02, 0x0D, 0x1A, 0x20, 0x2A, 0x7F, 0x80, 0xFF,
      *'0123456789+-.YNTFCMGBIDLPVWQ@'.bytes
    ].freeze
    INTERESTING_INTS = [
      0, 1, 2, 7, 8, 31, 32, 33, 63, 64, 255, 256, 511, 512, 513, 0x7FFF, 0x8000, 0xFFFF, 0x10000,
      0x7FFFFFFF, 0x80000000, 0xFFFFFFFF, -1
    ].freeze
    VERSIONS = [*DBF::VersionConfig::VERSIONS.keys.map { |key| key.to_i(16) }, 0x00, 0xFF].freeze
    # Offsets of the dBase header fields: version, record count, header
    # length, record length, language driver.
    HEADER_FIELDS = [[0, 1], [4, 4], [8, 2], [10, 2], [29, 1]].freeze
    # Offsets within a 32-byte column descriptor: type, length, decimal.
    DESCRIPTOR_FIELDS = [[11, 1], [16, 1], [17, 1], [12, 4]].freeze
    # Generic operators; #apply mixes in format-aware header mutations.
    OPERATORS = [
      :flip_bit, :random_byte, :interesting_byte, :random_int, :random_int,
      :delete_chunk, :insert_chunk, :truncate, :splice, :copy_chunk, :append_chunk
    ].freeze

    def initialize(rng, splice_pool)
      @rng = rng
      @splice_pool = splice_pool
    end

    def mutate(input)
      dbf = input.dbf.dup
      memo = input.memo&.dup
      case @rng.rand(10)
      when 0..6 then dbf = mutate_bytes(dbf, table: true)
      when 7, 8 then memo ? memo = mutate_bytes(memo, table: false) : dbf = mutate_bytes(dbf, table: true)
      else
        dbf = mutate_bytes(dbf, table: true)
        memo = memo ? mutate_bytes(memo, table: false) : pick_memo
      end
      Input.new(dbf.byteslice(0, MAX_INPUT_SIZE), memo&.byteslice(0, MAX_INPUT_SIZE))
    end

    private

    def pick_memo
      return nil if @rng.rand(2).zero?

      @splice_pool.select(&:memo).sample(random: @rng)&.memo&.dup
    end

    def mutate_bytes(bytes, table:)
      (1 + @rng.rand(@rng.rand(2).zero? ? 2 : 8)).times do
        bytes = apply(bytes, table:)
      end
      bytes
    end

    def apply(bytes, table:)
      return bytes + random_bytes(1 + @rng.rand(64)) if bytes.empty?
      return send(OPERATORS.sample(random: @rng), bytes) if @rng.rand(13) < OPERATORS.size

      table ? mutate_header(bytes) : mutate_memo_header(bytes)
    end

    def random_byte(bytes) = set_byte(bytes, @rng.rand(256))
    def interesting_byte(bytes) = set_byte(bytes, INTERESTING_BYTES.sample(random: @rng))
    def random_int(bytes) = set_int(bytes, @rng.rand(bytes.bytesize))

    def flip_bit(bytes)
      offset = @rng.rand(bytes.bytesize)
      bytes.setbyte(offset, bytes.getbyte(offset) ^ (1 << @rng.rand(8)))
      bytes
    end

    def set_byte(bytes, value, offset = @rng.rand(bytes.bytesize))
      bytes.setbyte(offset, value) if offset < bytes.bytesize
      bytes
    end

    def set_int(bytes, offset, width = [1, 2, 4].sample(random: @rng))
      value = INTERESTING_INTS.sample(random: @rng)
      value += @rng.rand(-2..2) if @rng.rand(3).zero?
      format = {1 => 'C', 2 => @rng.rand(2).zero? ? 'v' : 'n', 4 => @rng.rand(2).zero? ? 'V' : 'N'}[width]
      packed = [value & ((1 << (width * 8)) - 1)].pack(format)
      bytes[offset, width] = packed if offset + width <= bytes.bytesize
      bytes
    end

    def mutate_header(bytes)
      if @rng.rand(3).zero?
        set_byte(bytes, VERSIONS.sample(random: @rng), 0)
      elsif @rng.rand(2).zero?
        offset, width = HEADER_FIELDS.sample(random: @rng)
        set_int(bytes, offset, width)
      else
        offset, width = DESCRIPTOR_FIELDS.sample(random: @rng)
        set_int(bytes, 32 + (32 * @rng.rand(8)) + offset, width)
      end
    end

    # FoxPro memo headers hold the block size at offset 6; dBase IV blocks
    # start with a signature and a length; every format addresses blocks of
    # 512 (or the declared) bytes.
    def mutate_memo_header(bytes)
      offset = [0, 4, 6, 512, 516, 520, 1024, 1028].sample(random: @rng)
      offset = (@rng.rand([bytes.bytesize / 64, 1].max) * 64) + [0, 4].sample(random: @rng) if @rng.rand(3).zero?
      set_int(bytes, offset, [2, 4].sample(random: @rng))
    end

    def chunk_length(bytes)
      limit = @rng.rand(4).zero? ? bytes.bytesize : 64
      1 + @rng.rand([limit, 1].max)
    end

    def delete_chunk(bytes)
      offset = @rng.rand(bytes.bytesize)
      bytes.byteslice(0, offset) + bytes.byteslice((offset + chunk_length(bytes))..).to_s
    end

    def insert_chunk(bytes)
      offset = @rng.rand(bytes.bytesize + 1)
      chunk = @rng.rand(2).zero? ? random_bytes(chunk_length(bytes)) : bytes.byteslice(@rng.rand(bytes.bytesize), chunk_length(bytes))
      bytes.byteslice(0, offset) + chunk + bytes.byteslice(offset..).to_s
    end

    def append_chunk(bytes)
      bytes + bytes.byteslice(@rng.rand(bytes.bytesize), chunk_length(bytes))
    end

    def copy_chunk(bytes)
      chunk = bytes.byteslice(@rng.rand(bytes.bytesize), chunk_length(bytes))
      offset = @rng.rand(bytes.bytesize)
      bytes[offset, chunk.bytesize] = chunk.byteslice(0, bytes.bytesize - offset)
      bytes
    end

    def truncate(bytes)
      bytes.byteslice(0, @rng.rand(bytes.bytesize))
    end

    def splice(bytes)
      donor = @splice_pool.sample(random: @rng)
      source = @rng.rand(2).zero? || !donor.memo ? donor.dbf : donor.memo
      return bytes if source.empty?

      chunk = source.byteslice(@rng.rand(source.bytesize), chunk_length(source))
      offset = @rng.rand(bytes.bytesize)
      bytes.byteslice(0, offset) + chunk + bytes.byteslice((offset + chunk.bytesize)..).to_s
    end

    def random_bytes(length)
      @rng.bytes(length)
    end
  end

  # Shrinks an input while a predicate keeps holding: first by cutting the
  # tail (which keeps header offsets intact), then by deleting chunks.
  class Minimizer
    def initialize(time_limit)
      @time_limit = time_limit
    end

    def minimize(input, &)
      @deadline = now + @time_limit
      dbf = shrink(input.dbf) { |candidate| yield(Input.new(candidate, input.memo)) }
      memo = input.memo
      if memo
        memo = nil if yield(Input.new(dbf, nil))
        memo &&= shrink(memo) { |candidate| yield(Input.new(dbf, candidate)) }
      end
      Input.new(dbf, memo)
    end

    private

    def shrink(bytes, &)
      bytes = truncate_tail(bytes, &)
      chunk = bytes.bytesize / 2
      while chunk.positive? && now < @deadline
        bytes = remove_chunks(bytes, chunk, &)
        chunk /= 2
      end
      bytes
    end

    def truncate_tail(bytes)
      low = 0
      high = bytes.bytesize
      while low < high && now < @deadline
        mid = (low + high) / 2
        if yield(bytes.byteslice(0, mid))
          high = mid
        else
          low = mid + 1
        end
      end
      bytes.byteslice(0, high)
    end

    def remove_chunks(bytes, chunk)
      offset = 0
      while offset < bytes.bytesize && now < @deadline
        candidate = bytes.byteslice(0, offset) + bytes.byteslice((offset + chunk)..).to_s
        if yield(candidate)
          bytes = candidate
        else
          offset += chunk
        end
      end
      bytes
    end

    def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  # Loads the fixture pairs, cutting oversized tables down to whole records.
  module Seeds
    module_function

    def load
      files = Dir.glob(File.join(FIXTURES, '**', '*')).select { |path| File.file?(path) }
      by_stem = files.group_by { |path| path.sub(/\.[^.]+\z/, '').downcase }
      files.filter_map do |path|
        next unless DATA_EXTENSIONS.include?(File.extname(path).downcase)

        memo = by_stem[path.sub(/\.[^.]+\z/, '').downcase].find { |other| MEMO_EXTENSIONS.include?(File.extname(other).downcase) }
        Input.new(trim(File.binread(path)), memo && File.binread(memo))
      end
    end

    def trim(bytes)
      return bytes if bytes.bytesize <= MAX_SEED_SIZE || bytes.getbyte(0) == 0x02

      header_length, record_length = bytes.unpack('x8 v2')
      return bytes.byteslice(0, MAX_SEED_SIZE) unless record_length.positive? && header_length < MAX_SEED_SIZE

      count = (MAX_SEED_SIZE - header_length) / record_length
      trimmed = bytes.byteslice(0, header_length + (count * record_length))
      trimmed[4, 4] = [count].pack('V')
      trimmed
    end
  end

  # The fuzzing loop for one worker process.
  class Worker
    def initialize(options, index)
      @options = options
      @index = index
      @rng = Random.new(options[:seed] + index)
      @target = Target.new(**options.slice(:budget, :alloc_ratio, :alloc_floor, :hard_limit))
      @seeds = Seeds.load
      @corpus = @seeds.dup
      @mutator = Mutator.new(@rng, @seeds)
      @features = {}
      @reported = 0
      @execs = 0
      @fanouts = 0
      @corpus_dir = File.join(options[:out], 'corpus')
      @shared = {}
      FileUtils.mkdir_p(@corpus_dir)
    end

    # @return [Integer] number of new findings
    def run
      started = now
      deadline = started + @options[:time]
      @corpus.each { |input| execute(input) }
      sync
      @last_status = started
      until now > deadline || (@options[:runs] && @execs >= @options[:runs])
        execute(@mutator.mutate(@corpus.sample(random: @rng)))
        next unless now - @last_status > 10

        sync
        status(started)
      end
      status(started)
      @reported
    end

    private

    def execute(input)
      @execs += 1
      finding = @target.run(input)
      fresh = new_coverage?
      if finding&.kind == :fanout
        @fanouts += 1
      elsif finding
        report(input, finding)
      elsif fresh
        @corpus << input
        @corpus.delete_at(@seeds.size + @rng.rand(@corpus.size - @seeds.size)) if @corpus.size > MAX_CORPUS
        share(input)
      end
    end

    # Workers pool the inputs that found new coverage in <out>/corpus, so
    # parallel workers build on each other's progress and a later run
    # resumes where this one stopped. The memo is written before the .dbf
    # that names the entry, and each file is renamed into place whole.
    def share(input)
      name = Digest::SHA256.hexdigest("#{input.dbf}\0#{input.memo}")[0, 16]
      return if @shared.key?(name)

      @shared[name] = true
      publish("#{name}.memo", input.memo) if input.memo
      publish("#{name}.dbf", input.dbf)
    end

    def publish(file, bytes)
      tmp = File.join(@corpus_dir, ".#{file}.#{Process.pid}")
      File.binwrite(tmp, bytes)
      File.rename(tmp, File.join(@corpus_dir, file))
    end

    # Runs the entries other workers have shared since the last sync.
    def sync
      Dir.children(@corpus_dir).each do |file|
        name = file.delete_suffix('.dbf')
        next if name == file || @shared.key?(name)

        @shared[name] = true
        memo = File.join(@corpus_dir, "#{name}.memo")
        execute(Input.new(File.binread(File.join(@corpus_dir, file)), File.exist?(memo) ? File.binread(memo) : nil))
      end
    end

    # Features are (branch, log2 hit-count bucket) pairs, as in AFL.
    def new_coverage?
      fresh = false
      Coverage.result(stop: false, clear: true).each do |path, result|
        next unless path.start_with?(LIB)

        result[:branches].each_value do |targets|
          targets.each do |target, count|
            next if count.zero?

            key = [target, count.bit_length].hash
            fresh = true unless @features.key?(key)
            @features[key] = true
          end
        end
      end
      fresh
    end

    def report(input, finding)
      base = File.join(@options[:out], "#{finding.kind}-#{Digest::SHA256.hexdigest(finding.signature)[0, 10]}")
      return if File.exist?("#{base}.txt")

      # A slow or allocation-heavy run may be noise; it must reproduce.
      return unless confirmed?(input, finding) && claim("#{base}.txt")

      minimal = Minimizer.new(@options[:minimize_time]).minimize(input) { |candidate| same?(candidate, finding) }
      final = @target.run(minimal) || finding
      write(base, minimal, final)
      @reported += 1
      log "NEW #{final.kind} #{final.signature} (#{minimal.size} bytes) -> #{base}.txt"
    end

    # Creates the report exclusively, so when several workers hit the same
    # finding at once only one of them minimises it.
    def claim(path)
      File.open(path, File::WRONLY | File::CREAT | File::EXCL) { nil }
      true
    rescue Errno::EEXIST
      false
    end

    def confirmed?(input, finding)
      [:crash, :hang].include?(finding.kind) || same?(input, finding)
    end

    def same?(input, finding)
      @target.run(input)&.signature == finding.signature
    end

    def write(base, input, finding)
      FileUtils.mkdir_p(File.dirname(base))
      File.binwrite("#{base}.dbf", input.dbf)
      File.binwrite("#{base}.memo", input.memo) if input.memo
      File.write("#{base}.txt", describe(base, input, finding))
    end

    def describe(base, input, finding)
      error = finding.error
      lines = [
        "kind:      #{finding.kind}",
        "signature: #{finding.signature}",
        "step:      #{finding.step}",
        format('elapsed:   %.3fs', finding.elapsed),
        "allocated: #{finding.allocated} bytes for #{input.size} input bytes",
        "dbf:       #{input.dbf.bytesize} bytes, memo: #{input.memo ? input.memo.bytesize : 'none'}"
      ]
      lines.push("error:     #{error.class}: #{error.message}", '', *error.backtrace.first(15)) if error
      lines << '' << 'Reproduce:' << "  ruby spec/fuzz/fuzz.rb --repro #{base}.dbf#{" #{base}.memo" if input.memo}"
      if input.size <= 1024
        lines << '' << "dbf  = #{input.dbf.inspect}.b"
        lines << "memo = #{input.memo.inspect}.b" if input.memo
      end
      "#{lines.join("\n")}\n"
    end

    def status(started)
      @last_status = now
      elapsed = now - started
      log format('%<t>.0fs execs=%<e>d (%<r>.0f/s) corpus=%<c>d features=%<f>d fanout=%<o>d new findings=%<n>d',
                 t: elapsed, e: @execs, r: @execs / elapsed, c: @corpus.size, f: @features.size, o: @fanouts, n: @reported)
    end

    def log(message)
      warn "[fuzz #{@index}] #{message}"
    end

    def now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end

  module CLI
    module_function

    def parse(argv)
      options = {
        time: Float(ENV.fetch('FUZZ_TIME', 60)), jobs: Integer(ENV.fetch('FUZZ_JOBS', 1)),
        seed: Integer(ENV.fetch('FUZZ_SEED', Random.new_seed % (2**31))), runs: nil,
        budget: 1.0, hard_limit: 10.0, alloc_ratio: 2048, alloc_floor: 8 * 1024 * 1024,
        minimize_time: 60.0, out: File.join(ROOT, 'tmp', 'fuzz'), repro: nil
      }
      OptionParser.new do |opts|
        opts.banner = 'Usage: ruby spec/fuzz/fuzz.rb [options]'
        opts.on('--time SECONDS', Float, 'How long each worker fuzzes (default 60)') { |value| options[:time] = value }
        opts.on('--runs N', Integer, 'Stop each worker after N executions') { |value| options[:runs] = value }
        opts.on('--jobs N', Integer, 'Worker processes (default 1)') { |value| options[:jobs] = value }
        opts.on('--seed N', Integer, 'Random seed') { |value| options[:seed] = value }
        opts.on('--budget SECONDS', Float, 'Report inputs slower than this (default 1.0)') { |value| options[:budget] = value }
        opts.on('--hard-limit SECONDS', Float, 'Abort inputs slower than this (default 10)') { |value| options[:hard_limit] = value }
        opts.on('--alloc-ratio N', Integer, 'Report inputs allocating more than N x their size ... (default 2048)') { |value| options[:alloc_ratio] = value }
        opts.on('--alloc-floor BYTES', Integer, '... plus this many bytes (default 8 MiB)') { |value| options[:alloc_floor] = value }
        opts.on('--minimize-time SECONDS', Float, 'Time spent shrinking each finding (default 60)') { |value| options[:minimize_time] = value }
        opts.on('--out DIR', 'Where findings are written (default tmp/fuzz)') { |value| options[:out] = File.expand_path(value) }
        opts.on('--repro DBF [MEMO]', 'Replay one input and print any error') { |value| options[:repro] = value }
      end.parse!(argv)
      options[:memo] = argv.first
      options
    end

    def repro(options)
      input = Input.new(File.binread(options[:repro]), options[:memo] && File.binread(options[:memo]))
      target = Target.new(**options.slice(:budget, :alloc_ratio, :alloc_floor, :hard_limit))
      finding = target.run(input)
      case finding&.kind
      when nil then warn 'no finding'
      when :fanout then warn 'memo fan-out limit reached (known amplification, not reported)'
      else warn format('%<k>s: %<s>s (%<t>.3fs, %<a>d bytes)', k: finding.kind, s: finding.signature, t: finding.elapsed, a: finding.allocated)
      end
      target.replay(input) if finding&.kind == :crash
      finding && finding.kind != :fanout ? 1 : 0
    end

    def fuzz(options)
      warn "[fuzz] seed=#{options[:seed]} time=#{options[:time]}s jobs=#{options[:jobs]} out=#{options[:out]}"
      return Worker.new(options, 0).run.positive? ? 1 : 0 if options[:jobs] <= 1

      pids = Array.new(options[:jobs]) { |index| fork { exit(Worker.new(options, index).run.positive? ? 1 : 0) } }
      pids.map { |pid| Process.wait2(pid).last.success? }.all? ? 0 : 1
    end

    def main(argv)
      # Specs (and the String column decoder) assume UTF-8 output.
      Encoding.default_external = Encoding::UTF_8
      options = parse(argv)
      options[:repro] ? repro(options) : fuzz(options)
    end
  end
end

exit DBFFuzz::CLI.main(ARGV) if $PROGRAM_NAME == __FILE__
