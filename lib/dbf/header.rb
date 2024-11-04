module DBF
  # Represents the header section of a DBF file containing metadata
  class Header
    attr_reader :version, :record_count, :header_length, :record_length, :encoding_key, :encoding

    # Initialize a new DBF::Header
    #
    # @param data [String] The raw header data to parse
    def initialize(data)
      @data = data
      unpack_header
    end

    private

    # Unpacks the header data based on the DBF version
    def unpack_header
      @version = unpack_version

      unpack_fields_for_version
    end

    # Extracts the DBF version from the header
    def unpack_version
      @data.unpack1('H2')
    end

    # Unpacks the appropriate fields based on DBF version
    def unpack_fields_for_version
      if @version == '02'
        unpack_version_02_fields
      else
        unpack_standard_fields
      end
    end

    # Unpacks fields specific to version 02 format
    def unpack_version_02_fields
      @record_count, @record_length = @data.unpack('x v x3 v')
      @header_length = 521
    end

    # Unpacks fields for standard DBF format
    def unpack_standard_fields
      @record_count, @header_length, @record_length, @encoding_key = 
        @data.unpack('x x3 V v2 x17 H2')
      @encoding = DBF::ENCODINGS[@encoding_key]
    end
  end
end
