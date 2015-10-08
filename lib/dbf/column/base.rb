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

        validate_length
        validate_name
      end

      # Cast value to native type
      #
      # @param [String] value
      # @return [Fixnum, Float, Date, DateTime, Boolean, String]
      def type_cast(value)
        return nil if length == 0

        meth = type_cast_methods[type]
        meth ? send(meth, value) : encode_string(value, true)
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
          un = name.dup
          un.gsub!(/::/, '/')
          un.gsub!(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          un.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
          un.tr!('-', '_')
          un.downcase!
          un
        end
      end

      def to_hash
        {name: name, type: type, length: length, decimal: decimal}
      end

      private

      def type_cast_methods # nodoc
        {
          'N' => :unpack_number,
          'I' => :unpack_signed_long,
          'F' => :unpack_float,
          'Y' => :unpack_currency,
          'D' => :decode_date,
          'T' => :decode_datetime,
          'L' => :boolean,
          'M' => :decode_memo,
          'B' => :unpack_double
        }
      end

      def decode_date(value) # nodoc
        value.gsub!(' ', '0')
        value !~ /\S/ ? nil : Date.parse(value)
      rescue
        nil
      end

      def decode_datetime(value) # nodoc
        days, msecs = value.unpack('l2')
        secs = (msecs / 1000).to_i
        DateTime.jd(days, (secs / 3600).to_i, (secs / 60).to_i % 60, secs % 60)
      rescue
        nil
      end

      def decode_memo(value) # nodoc
        value && encode_string(value)
      end

      def unpack_number(value) # nodoc
        decimal.zero? ? value.to_i : value.to_f
      end

      def unpack_currency(value) # nodoc
        (value.unpack('q<')[0] / 10_000.0).to_f
      end

      def unpack_signed_long(value) # nodoc
        value.unpack('l<')[0]
      end

      def unpack_float(value) # nodoc
        value.to_f
      end

      def unpack_double(value) # nodoc
        value.unpack('E')[0]
      end

      def boolean(value) # nodoc
        value.strip =~ /^(y|t)$/i ? true : false
      end

      def encode_string(value, strip_output = false) # nodoc
        output =
          if supports_encoding? && table.supports_string_encoding?
            value.to_s.force_encoding(@encoding).encode(*encoding_args)
          elsif supports_encoding? && table.supports_iconv?
            Iconv.conv('UTF-8', @encoding, value.to_s)
          else
            value
          end

        strip_output ? output.strip : output
      end

      def encoding_args # nodoc
        [Encoding.default_external, {:undef => :replace, :invalid => :replace}]
      end

      def schema_data_type # nodoc
        case type
        when 'N', 'F'
          decimal > 0 ? ':float' : ':integer'
        when 'I'
          ':integer'
        when 'Y'
          ':decimal, :precision => 15, :scale => 4'
        when 'D'
          ':date'
        when 'T'
          ':datetime'
        when 'L'
          ':boolean'
        when 'M'
          ':text'
        when 'B'
          if DBF::Table::FOXPRO_VERSIONS.keys.include?(@version)
            ':float'
          else
            ':text'
          end
        else
          ":string, :limit => #{length}"
        end
      end

      def clean(value) # nodoc
        truncated_value = value.strip.partition("\x00").first
        truncated_value.gsub(/[^\x20-\x7E]/, '')
      end

      def validate_length
        raise LengthError, 'field length must be 0 or greater' if length < 0
      end

      def validate_name
        raise NameError, 'column name cannot be empty' if @name.empty?
      end

      def supports_encoding?
        @encoding && table.supports_encoding?
      end
    end
  end
end
