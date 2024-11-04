module DBF
  class Column
    extend Forwardable

    class LengthError < StandardError; end
    class NameError < StandardError; end

    attr_reader :table, :name, :type, :length, :decimal, :encoding

    def_delegator :type_cast_class, :type_cast

    # Maps DBF column types to their corresponding type casting classes
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
    }.tap { |h| h.default = ColumnType::String }.freeze

    # Initialize a new DBF::Column
    #
    # @param table [DBF::Table] The table this column belongs to
    # @param name [String] The name of the column
    # @param type [String] The DBF type code for this column
    # @param length [Integer] The length of the column in bytes
    # @param decimal [Integer] The number of decimal places (for numeric columns)
    def initialize(table, name, type, length, decimal)
      @table = table
      @encoding = table.encoding
      @name = clean(name)
      @type = type
      @length = length
      @decimal = decimal
      @version = table.version

      validate_length
      validate_name
    end

    # Returns true if the column is a memo type
    #
    # @return [Boolean]
    def memo?
      @memo ||= type == 'M'
    end

    # Returns the column metadata as a Hash
    #
    # @return [Hash] Column metadata including :name, :type, :length, and :decimal
    def to_hash
      {
        name: name,
        type: type,
        length: length,
        decimal: decimal
      }
    end

    # Returns the column name in underscore format
    #
    # Converts camelCase or PascalCase to snake_case
    # Example: "MyColumn" becomes "my_column"
    #
    # @return [String] The underscored column name
    def underscored_name
      @underscored_name ||= name
        .gsub(/([a-z\d])([A-Z])/, '\1_\2')
        .tr('-', '_')
        .downcase
    end

    private

    # Cleans the raw column name by removing null bytes and whitespace
    def clean(value)
      table.encode_string(value.strip.partition("\x00").first)
    end

    # Returns the appropriate type casting class for this column
    def type_cast_class
      @type_cast_class ||= begin
        klass = length.zero? ? ColumnType::Nil : TYPE_CAST_CLASS[type.to_sym]
        klass.new(self)
      end
    end

    # Validates that the column length is not negative
    def validate_length
      raise LengthError, 'field length must be 0 or greater' if length.negative?
    end

    # Validates that the column has a name
    def validate_name
      raise NameError, 'column name cannot be empty' if @name.empty?
    end
  end
end
