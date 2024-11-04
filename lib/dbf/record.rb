module DBF
  # An instance of DBF::Record represents a row in the DBF file
  class Record
    # Initialize a new DBF::Record
    #
    # @param data [String, StringIO] The raw data for this record
    # @param columns [Array<Column>] The column definitions for this record
    # @param version [String] The DBF file version
    # @param memo [DBF::Memo, nil] The memo file handler, if one exists
    def initialize(data, columns, version, memo)
      @data = StringIO.new(data)
      @columns = columns
      @version = version
      @memo = memo
    end

    # Checks equality with another record by comparing attributes
    #
    # @param other [DBF::Record] The record to compare with
    # @return [Boolean] True if records have identical attributes
    def ==(other)
      other.respond_to?(:attributes) && other.attributes == attributes
    end

    # Retrieves a field value by column name
    #
    # @param name [String, Symbol] The column name to look up
    # @return The value for the named column
    def [](name)
      key = name.to_s
      if attributes.key?(key)
        attributes[key]
      elsif (index = underscored_column_names.index(key))
        attributes[@columns[index].name]
      end
    end

    # Returns all record attributes as a hash
    #
    # @return [Hash{String => Object}] Column names mapped to their values
    def attributes
      @attributes ||= column_names.zip(to_a).to_h
    end

    # Checks if record matches all search criteria
    #
    # @param options [Hash{Symbol => Object}] The search criteria
    # @return [Boolean] True if all criteria match
    def match?(options)
      options.all? { |key, value| self[key] == value }
    end

    # Returns all field values as an array
    #
    # @return [Array] The values for each column in order
    def to_a
      @to_a ||= @columns.map { |column| init_attribute(column) }
    end

    private

    def column_names
      @column_names ||= @columns.map(&:name)
    end

    def get_data(column)
      @data.read(column.length)
    end

    def get_memo(column)
      if @memo
        @memo.get(memo_start_block(column))
      else
        # The memo file is missing, so read ahead to next record and return nil
        @data.read(column.length)
        nil
      end
    end

    def init_attribute(column)
      value = column.memo? ? get_memo(column) : get_data(column)
      column.type_cast(value)
    end

    def memo_start_block(column)
      data = get_data(column)
      # Versions 30 and 31 store memo pointers as little-endian 32-bit integers
      data = data.unpack1('V') if %w[30 31].include?(@version)
      data.to_i
    end

    def method_missing(method, *args)
      if (index = underscored_column_names.index(method.to_s))
        attributes[@columns[index].name]
      else
        super
      end
    end

    def respond_to_missing?(method, *)
      underscored_column_names.include?(method.to_s) || super
    end

    def underscored_column_names
      @underscored_column_names ||= @columns.map(&:underscored_name)
    end
  end
end
