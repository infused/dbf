module DBF
  class Column
    extend Forwardable

    class LengthError < StandardError
    end

    class NameError < StandardError
    end

    attr_reader :table, :name, :type, :length, :decimal
    def_delegator :type_cast_class, :type_cast

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
      G: ColumnType::General,
      '+'.to_sym => ColumnType::SignedLong2
    }
    TYPE_CAST_CLASS.default = ColumnType::String
    TYPE_CAST_CLASS.freeze

    # Initialize a new DBF::Column
    #
    # @param table [String]
    # @param name [String]
    # @param type [String]
    # @param length [Integer]
    # @param decimal [Integer]
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

    # Underscored name
    #
    # This is the column name converted to underscore format.
    # For example, MyColumn will be returned as my_column.
    #
    # @return [String]
    def underscored_name
      @underscored_name ||= begin
        name.gsub(/([a-z\d])([A-Z])/, '\1_\2').tr('-', '_').downcase
      end
    end

    private

    def clean(value) # :nodoc:
      value.strip.gsub("\x00", '').gsub(/[^\x20-\x7E]/, '')
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
