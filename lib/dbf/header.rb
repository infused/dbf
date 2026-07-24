# frozen_string_literal: true

module DBF
  class Header
    HEADER_SIZE = 32

    attr_reader :version, :record_count, :header_length, :record_length, :encoding_key, :encoding

    def initialize(data)
      # Pad a nil or truncated header read so unpacking a short file yields
      # empty values instead of raising.
      data = data.to_s.b.ljust(HEADER_SIZE, "\x00")
      @version = data.unpack1('H2')
      @encoding_key = nil
      @encoding = nil

      case @version
      when '02'
        @record_count, @record_length = data.unpack('x v x3 v')
        @header_length = 521
      else
        @record_count, @header_length, @record_length, @encoding_key = data.unpack('x x3 V v2 x17 H2')
        @encoding = DBF::ENCODINGS[@encoding_key]
      end
    end
  end
end
