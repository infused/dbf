# frozen_string_literal: true

module DBF
  class RecordIterator
    # Records are read in chunks of whole records totalling roughly this many
    # bytes, so enumerating a multi-gigabyte file (for example a shapefile
    # sidecar) needs only chunk-sized memory instead of the entire record
    # section at once.
    CHUNK_SIZE = 4 * 1024 * 1024

    def initialize(data, context, header_length, record_length, record_count, chunk_size: CHUNK_SIZE)
      @data = data
      @context = context
      @header_length = header_length
      @record_length = record_length
      @record_count = record_count
      @chunk_size = chunk_size
    end

    def each(&)
      return enum_for(:each) unless block_given?

      # A record_length of 0 from a crafted header cannot drive an unbounded
      # loop: capacity is 0 and enumeration ends immediately.
      remaining = record_capacity
      @data.seek(@header_length)

      while remaining.positive?
        wanted = [per_chunk, remaining].min
        buffer = @data.read(wanted * @record_length)
        break unless buffer

        whole_records = buffer.bytesize / @record_length
        break if whole_records.zero?

        yield_chunk(buffer, whole_records, &)
        remaining -= whole_records

        # A short read means the file ended earlier than the header promised
        break if whole_records < wanted
      end
    end

    private

    # Whole records per read; at least one so a record larger than the chunk
    # size still makes progress. Only called when record_length is positive.
    def per_chunk
      @per_chunk ||= [@chunk_size / @record_length, 1].max
    end

    def yield_chunk(buffer, count)
      pos = 0
      count.times do
        if buffer.getbyte(pos) == 0x2A
          yield nil
        else
          yield Record.new(buffer, @context, pos + 1)
        end
        pos += @record_length
      end
    end

    # Bound enumeration by the bytes actually available so a crafted header
    # (huge record_length * record_count) cannot force reads past the real
    # file size, while record_count still caps a file with trailing garbage.
    def record_capacity
      return 0 unless @record_length.positive?

      available = @data.size - @header_length
      return 0 if available.negative?

      [@record_count, available / @record_length].min
    end
  end
end
