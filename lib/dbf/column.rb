module DBF
  class Column
    extend Forwardable

    class LengthError < StandardError
    end

    class NameError < StandardError
    end

    attr_reader :table, :name, :type, :length, :decimal, :encoding

    def_delegator :type_cast_class, :type_cast

    # rubocop:disable Style/MutableConstant
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
      :+ => ColumnType::SignedLong2
    }
    # rubocop:enable Style/MutableConstant
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
      @encoding = table.encoding

      @table = table
      @name = clean(name)
      @type = type
      @length = length
      @decimal = decimal
      @version = table.version

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
      @underscored_name ||= name.gsub(/([a-z\d])([A-Z])/, '\1_\2').tr('-', '_').downcase
    end

    private

    def clean(value) # :nodoc:
      table.encode_string(value.strip.partition("\x00").first)
    end

    def type_cast_class # :nodoc:
      @type_cast_class ||= begin
        klass = @length == 0 ? ColumnType::Nil : TYPE_CAST_CLASS[type.to_sym]
        klass.new(self)
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
