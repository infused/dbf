module DBF
  class Column
    class LengthError < StandardError
    end

    class NameError < StandardError
    end

    attr_reader :table, :name, :type, :length, :decimal

    TYPE_CAST_CLASS = {
      N: ColumnType::Number,
      I: ColumnType::SignedLong,
      F: ColumnType::Float,
      Y: ColumnType::Currency,
      D: ColumnType::Date,
      T: ColumnType::DateTime,
      L: ColumnType::Boolean,
      M: ColumnType::Memo,
      B: ColumnType::Double,
      G: ColumnType::General
    }
    TYPE_CAST_CLASS.default = ColumnType::String
    TYPE_CAST_CLASS.freeze

    # Initialize a new DBF::Column
    #
    # @param [String] name
    # @param [String] type
    # @param [Integer] length
    # @param [Integer] decimal
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

    # Returns true if the column is a memo
    #
    # @return [Boolean]
    def memo?
      @memo ||= type == 'M'
    end

    # Returns a Hash with :name, :type, :length, and :decimal keys
    #
    # @return [Hash]
    def to_hash
      {name: name, type: type, length: length, decimal: decimal}
    end

    # Cast value to native type
    #
    # @param [String] value
    # @return [Integer, Float, Date, DateTime, Boolean, String]
    def type_cast(value)
      type_cast_class.type_cast(value)
    end

    # Underscored name
    #
    # This is the column name converted to underscore format.
    # For example, MyColumn will be returned as my_column.
    #
    # @return [String]
    def underscored_name
      @underscored_name ||= begin
        name.gsub(/::/, '/')
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .tr('-', '_')
          .downcase
      end
    end

    private

    def clean(value) # :nodoc:
      truncated_value = value.strip.partition("\x00").first
      truncated_value.gsub(/[^\x20-\x7E]/, '')
    end

    def encode(value, strip_output = false) # :nodoc:
      return value unless value.respond_to?(:encoding)

      output = @encoding ? encode_string(value) : value
      strip_output ? output.strip : output
    end

    def encoding_args # :nodoc:
      @encoding_args ||= [
        Encoding.default_external,
        {undef: :replace, invalid: :replace}
      ]
    end

    def encode_string(string) # :nodoc:
      string.force_encoding(@encoding).encode(*encoding_args)
    end

    def type_cast_class # :nodoc:
      @type_cast_class ||= begin
        klass = @length == 0 ? ColumnType::Nil : TYPE_CAST_CLASS[type.to_sym]
        klass.new(@decimal, @encoding)
      end
    end

    def validate_length # :nodoc:
      raise LengthError, 'field length must be 0 or greater' if length < 0
    end

    def validate_name # :nodoc:
      raise NameError, 'column name cannot be empty' if @name.empty?
    end
  end
end
