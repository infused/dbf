module DBF
  class Header
    attr_reader :version
    attr_reader :record_count
    attr_reader :header_length
    attr_reader :record_length
    attr_reader :encoding_key
    attr_reader :encoding

    def initialize(data)
      @data = data
      unpack_header
    end

    def unpack_header
      @version = @data.unpack('H2').first

      case @version
      when '02'
        @record_count, @record_length = @data.unpack('x v x3 v')
        @header_length = 521
      else
        @record_count, @header_length, @record_length, @encoding_key = @data.unpack('x x3 V v2 x17 H2')
        @encoding = DBF::ENCODINGS[@encoding_key]
      end
    end
  end
end
