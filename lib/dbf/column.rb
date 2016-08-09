module DBF
  class Column
    # Raised if length is less than 1
    class LengthError < StandardError; end

    # Raised if name is empty
    class NameError < StandardError; end

    attr_reader :table
    attr_reader :name
    attr_reader :type
    attr_reader :length
    attr_reader :decimal
    attr_reader :position
    attr_reader :offset

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

    # Initialize a new DBF::Column
    #
    # @param [String] name
    # @param [String] type
    # @param [Fixnum] length
    # @param [Fixnum] decimal
    # @param [Fixnum] position
    # @param [Fixnum] offset
    def initialize(table, name, type, length, decimal, position = nil, offset = nil)
      @table = table
      @name = clean(name)
      @type = type
      @length = length
      @decimal = decimal
      @version = table.version
      @encoding = table.encoding
      @position = position
      @offset = offset

      validate_length
      validate_name
    end

    # Cast value to native type
    #
    # @param [String] value
    # @return [Fixnum, Float, Date, DateTime, Boolean, String]
    def type_cast(value)
      type_cast_class.type_cast(value)
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

    # Sequel Schema definition
    #
    # @return [String]
    def sequel_schema_definition
      ":#{underscored_name}, #{schema_data_type(:sequel)}\n"
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
      Hash[to_hash_method_map]
    end

    def to_hash_methods
      [:name, :type, :length, :decimal, :position, :offset]
    end

    def to_hash_method_map
      to_hash_methods.map {|m| [m.to_sym, send(m)]}
    end

    private

    def type_cast_class # nodoc
      @type_cast_class ||= begin
        klass = @length == 0 ? ColumnType::Nil : TYPE_CAST_CLASS[type.to_sym]
        klass.new(@decimal, @encoding)
      end
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

    def schema_data_type(format = :activerecord) # nodoc
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
        if format == :sequel
          ":varchar, :size => #{length}"
        else
          ":string, :limit => #{length}"
        end
      end
    end

    def clean(value) # nodoc
      truncated_value = value.strip.partition("\x00").first
      truncated_value.gsub(/[^\x20-\x7E]/, '')
    end

    def validate_length # nodoc
      raise LengthError, 'field length must be 0 or greater' if length < 0
    end

    def validate_name # nodoc
      raise NameError, 'column name cannot be empty' if @name.empty?
    end
  end
end
