module DBF
  class Column
    # Raised if length is less than 1
    class LengthError < StandardError; end

    # Raised if name is empty
    class NameError < StandardError; end

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

      klass = type_cast_class[type.to_sym]
      cast_value = klass.new(value, decimal).type_cast
      binary? ? cast_value : encode(cast_value)
    end

    # Returns true if the column is a memo
    #
    # @return [Boolean]
    def memo?
      @memo ||= type == 'M'
    end

    # Returns true if the column contains binary data
    #
    # @return [Boolean]
    def binary?
      @binary ||= type == 'G'
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

    def type_cast_class # nodoc
      h = Hash.new(ColumnType::String)
      h[:N] = ColumnType::Number
      h[:I] = ColumnType::SignedLong
      h[:F] = ColumnType::Float
      h[:Y] = ColumnType::Currency
      h[:D] = ColumnType::Date
      h[:T] = ColumnType::DateTime
      h[:L] = ColumnType::Boolean
      h[:M] = ColumnType::Memo
      h[:B] = ColumnType::Double
      h[:G] = ColumnType::General
      h
    end

    def encode(value, strip_output = false) # nodoc
      return value if !value.respond_to?(:encoding)

      output = @encoding ? encode_string(value) : value
      strip_output ? output.strip : output
    end

    def encode_string(string)
      string.force_encoding(@encoding).encode(*encoding_args)
    end

    def encoding_args # nodoc
      @encoding_args ||= [
        Encoding.default_external,
        {undef: :replace, invalid: :replace}
      ]
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
  end
end
