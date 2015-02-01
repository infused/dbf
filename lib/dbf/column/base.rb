module DBF
  module Column
    # Raised if length is less than 1
    class LengthError < StandardError; end

    # Raised if name is empty
    class NameError < StandardError; end

    class Base
      attr_reader :table, :name, :type, :length, :decimal

      # Initialize a new DBF::Column
      #
      # @param [String] name
      # @param [String] type
      # @param [Fixnum] length
      # @param [Fixnum] decimal
      def initialize(table, name, type, length, decimal)
        @table = table
        @name = clean(name)
        @type = type
        @length = length
        @decimal = decimal
        @version = table.version
        @encoding = table.encoding

        unless length > 0
          raise LengthError, "field length must be greater than 0"
        end

        if @name.empty?
          raise NameError, "column name cannot be empty"
        end
      end

      # Cast value to native type
      #
      # @param [String] value
      # @return [Fixnum, Float, Date, DateTime, Boolean, String]
      def type_cast(value)
        case type
          when 'N' then unpack_number(value)
          when 'I' then unpack_unsigned_long(value)
          when 'F' then value.to_f
          when 'Y' then (unpack_unsigned_long(value) / 10000.0).to_f
          when 'D' then decode_date(value)
          when 'T' then decode_datetime(value)
          when 'L' then boolean(value)
          when 'M' then decode_memo(value)
          else          encode_string(value.to_s).strip
        end
      end

      # Returns true if the column is a memo
      #
      # @return [Boolean]
      def memo?
        @memo ||= type == 'M'
      end

      # Schema definition
      #
      # @return [String]
      def schema_definition
        "\"#{underscored_name}\", #{schema_data_type}\n"
      end

      # Underscored name
      #
      # This is the column name converted to underscore format.
      # For example, MyColumn will be returned as my_column.
      #
      # @return [String]
      def underscored_name
        @underscored_name ||= begin
          name.gsub(/::/, '/').
            gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
            gsub(/([a-z\d])([A-Z])/,'\1_\2').
            tr('-', '_').
            downcase
        end
      end

      private

      def decode_date(value) #nodoc
        value.gsub!(' ', '0')
        value !~ /\S/ ? nil : Date.parse(value)
      rescue
        nil
      end

      def decode_datetime(value) #nodoc
        days, msecs = value.unpack('l2')
        secs = (msecs / 1000).to_i
        DateTime.jd(days, (secs/3600).to_i, (secs/60).to_i % 60, secs % 60)
      rescue
        nil
      end

      def decode_memo(value) #nodoc
        value && encode_string(value)
      end

      def unpack_number(value) #nodoc
        decimal.zero? ? value.to_i : value.to_f
      end

      def unpack_unsigned_long(value) #nodoc
        value.unpack('V')[0]
      end

      def boolean(value) #nodoc
        value.strip =~ /^(y|t)$/i ? true : false
      end

      def encode_string(value) #nodoc
        if @encoding && table.supports_encoding?
          if table.supports_string_encoding?
            value.force_encoding(@encoding).encode(*encoding_args)
          elsif table.supports_iconv?
            Iconv.conv('UTF-8', @encoding, value)
          end
        else
          value
        end
      end

      def encoding_args #nodoc
        [Encoding.default_external, {:undef => :replace, :invalid => :replace}]
      end

      def schema_data_type #nodoc
        case type
        when "N", "F"
          decimal > 0 ? ":float" : ":integer"
        when "I"
          ":integer"
        when "Y"
          ":decimal, :precision => 15, :scale => 4"
        when "D"
          ":date"
        when "T"
          ":datetime"
        when "L"
          ":boolean"
        when "M"
          ":text"
        when "B"
          if DBF::Table::FOXPRO_VERSIONS.keys.include?(@version)
            decimal > 0 ? ":float" : ":integer"
          else
            ":text"
          end
        else
          ":string, :limit => #{length}"
        end
      end

      def clean(value) #nodoc
        truncated_value = value.strip.partition("\x00").first
        truncated_value.gsub(/[^\x20-\x7E]/, '')
      end

    end
  end
end
