module DBF
  class Header
    attr_reader :version, :record_count, :header_length, :record_length, :encoding_key, :encoding

    def initialize(data)
      @data = data
      unpack_header
    end

    def unpack_header
      @version = @data.unpack1('H2')

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
