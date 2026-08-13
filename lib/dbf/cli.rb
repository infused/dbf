# frozen_string_literal: true

require 'optparse'

module DBF
  class CLI
    USAGE = <<~HELP
      usage: dbf [-h|-s|-a|-c|-r|-j|-J] filename
        -h = print this message
        -v = print the DBF gem version
        -s = print summary information
        -a = create an ActiveRecord::Schema
        -r = create a Sequel migration
        -c = export as CSV
        -j = export as a JSON array
        -J = export as JSON Lines (one record per line)
    HELP

    # Bytes a terminal interprets as control or escape sequences. A crafted
    # DBF can carry these in column names and record values, so they are
    # replaced before file-derived text reaches an interactive terminal.
    CONTROL_BYTES = /[\x00-\x1F\x7F]/n
    # The same, but keeping CR and LF so CSV row separators survive.
    CONTROL_BYTES_KEEPING_NEWLINES = /[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/n

    # Replaces terminal control bytes. Substitution happens on a byte copy so
    # a value whose bytes are invalid in its encoding cannot raise here.
    #
    # @param value [Object]
    # @param pattern [Regexp]
    # @return [String]
    def self.sanitize(value, pattern = CONTROL_BYTES)
      string = value.to_s
      string.b.gsub(pattern, '?').force_encoding(string.encoding)
    end

    # Wraps an IO so text written to an interactive terminal is stripped of
    # control bytes. Redirected or piped output is never wrapped, so exported
    # data is passed through unaltered.
    class TerminalFilter
      def initialize(io)
        @io = io
      end

      def <<(data)
        @io << CLI.sanitize(data, CONTROL_BYTES_KEEPING_NEWLINES)
        self
      end

      def write(*data)
        @io.write(*data.map { |datum| CLI.sanitize(datum, CONTROL_BYTES_KEEPING_NEWLINES) })
      end

      def method_missing(name, ...) # :nodoc:
        @io.respond_to?(name) ? @io.send(name, ...) : super
      end

      def respond_to_missing?(name, include_private = false) # :nodoc:
        @io.respond_to?(name, include_private) || super
      end
    end

    def self.run(argv, stdout: $stdout, stderr: $stderr)
      new(argv, stdout: stdout, stderr: stderr).run
    end

    def initialize(argv, stdout: $stdout, stderr: $stderr)
      @argv = argv.dup
      @stdout = stdout
      @stderr = stderr
    end

    ACTIONS = {
      'a' => :print_ar_schema,
      'r' => :print_sequel_schema,
      's' => :print_summary,
      'c' => :print_csv,
      'j' => :print_json,
      'J' => :print_jsonl
    }.freeze

    def run
      params = OptionParser.new.getopts(@argv, 'hsacrvjJ')

      if params['v']
        print_version
      elsif params['h']
        print_help
      else
        filename = @argv.shift
        return missing_filename unless filename

        action = ACTIONS.find { |flag, _method| params[flag] }&.last
        send(action, filename) if action
      end
      0
    rescue DBF::FileNotFoundError => e
      @stderr.puts "DBF::FileNotFoundError: #{e.message}"
      1
    end

    private

    def print_version
      @stdout.puts "dbf version: #{DBF::VERSION}"
    end

    def print_help
      @stdout.puts USAGE
    end

    def missing_filename
      @stderr.puts 'You must supply a filename on the command line'
      1
    end

    # Always close the table when done: an open handle prevents deleting or
    # replacing the file on Windows.
    def with_table(filename, &) = DBF::Table.open(filename, &)

    def print_ar_schema(filename)
      with_table(filename) { |table| @stdout.puts terminal_safe(table.schema(:activerecord)) }
    end

    def print_sequel_schema(filename)
      with_table(filename) { |table| @stdout.puts terminal_safe(table.schema(:sequel)) }
    end

    def print_summary(filename)
      with_table(filename) { |table| write_summary(filename, table) }
    end

    def write_summary(filename, table)
      @stdout.puts
      @stdout.puts "Database: #{filename}"
      @stdout.puts "Type: (#{table.version}) #{table.version_description}"
      @stdout.puts "Encoding: #{table.header_encoding}" if table.header_encoding
      @stdout.puts "Memo File: #{table.has_memo_file? ? 'true' : 'false'}"
      @stdout.puts "Records: #{table.record_count}"
      @stdout.puts "\nFields:"
      @stdout.puts 'Name             Type       Length     Decimal'
      @stdout.puts '-' * 78
      table.columns.each do |f|
        # Column names and types come from the file. Always replace control
        # bytes here: they are never valid in a name and would otherwise both
        # emit escape sequences and break the column alignment below.
        @stdout.puts format('%-16s %-10s %-10s %-10s', self.class.sanitize(f.name), self.class.sanitize(f.type), f.length, f.decimal)
      end
    end

    def print_csv(filename)
      with_table(filename) { |table| table.to_csv(interactive? ? TerminalFilter.new(@stdout) : @stdout) }
    end

    # Streams a JSON array without materializing all records in memory.
    # JSON string escaping makes the output terminal-safe by construction:
    # control bytes are emitted as \uXXXX escapes.
    def print_json(filename)
      with_table(filename) { |table| write_json(table) }
    end

    def write_json(table)
      first = true
      @stdout.write('[')
      each_present_record(table) do |record|
        @stdout.write(first ? "\n" : ",\n")
        @stdout.write(json_record(record))
        first = false
      end
      @stdout.write("\n]\n")
    end

    # One JSON object per line (JSON Lines). Combined with chunked record
    # reading this exports arbitrarily large files in constant memory.
    def print_jsonl(filename)
      with_table(filename) { |table| write_jsonl(table) }
    end

    def write_jsonl(table)
      each_present_record(table) { |record| @stdout.write("#{json_record(record)}\n") }
    end

    # Deleted records have no attributes, so JSON export skips them.
    def each_present_record(table, &)
      table.each { |record| yield record if record }
    end

    def json_record(record)
      JSON.generate(record.attributes.to_h { |key, value| [json_safe(key), json_safe(value)] })
    end

    # JSON.generate raises on binary or invalidly encoded strings; represent
    # their bytes instead of raising, mirroring the CSV export behavior.
    def json_safe(value)
      return value unless value.is_a?(::String)

      value.encode(Encoding::UTF_8, invalid: :replace, undef: :replace, replace: '?')
    rescue Encoding::ConverterNotFoundError
      value.dup.force_encoding(Encoding::UTF_8).scrub('?')
    end

    # Exported data is only filtered when it is going to a terminal, so
    # redirecting or piping still produces byte-for-byte the original values.
    def terminal_safe(text)
      return text unless interactive?

      self.class.sanitize(text, CONTROL_BYTES_KEEPING_NEWLINES)
    end

    def interactive?
      @stdout.respond_to?(:tty?) && @stdout.tty?
    end
  end
end
