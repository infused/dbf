# frozen_string_literal: true

module DBF
  class RecordIterator
    def initialize(data, context, header_length, record_length, record_count)
      @data = data
      @context = context
      @header_length = header_length
      @record_length = record_length
      @record_count = record_count
    end

    def each
      buf = read_buffer
      return unless buf

      pos = 0
      @record_count.times do
        if buf.getbyte(pos) == 0x2A
          yield nil
        else
          yield Record.new(buf, @context, pos + 1)
        end
        pos += @record_length
      end
    end

    private

    def read_buffer
      @data.seek(@header_length)
      @data.read(@record_length * @record_count)
    end
  end
end
