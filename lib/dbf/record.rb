module DBF
  # An instance of DBF::Record represents a row in the DBF file
  class Record
    # Initialize a new DBF::Record
    #
    # @data [String, StringIO] data
    # @columns [Column]
    # @version [String]
    # @memo [DBF::Memo]
    def initialize(data, columns, version, memo)
      @data = StringIO.new(data)
      @columns = columns
      @version = version
      @memo = memo
    end

    # Equality
    #
    # @param [DBF::Record] other
    # @return [Boolean]
    def ==(other)
      other.respond_to?(:attributes) && other.attributes == attributes
    end

    # Reads attributes by column name
    #
    # @param [String, Symbol] key
    def [](name)
      key = name.to_s
      if attributes.key?(key)
        attributes[key]
      elsif index = underscored_column_names.index(key)
        attributes[@columns[index].name]
      end
    end

    # Record attributes
    #
    # @return [Hash]
    def attributes
      @attributes ||= Hash[attribute_map]
    end

    # Do all search parameters match?
    #
    # @param [Hash] options
    # @return [Boolean]
    def match?(options)
      options.all? { |key, value| self[key] == value }
    end

    # Maps a row to an array of values
    #
    # @return [Array]
    def to_a
      @columns.map { |column| attributes[column.name] }
    end

    private

    def attribute_map # :nodoc:
      @columns.map { |column| [column.name, init_attribute(column)] }
    end

    def get_data(column) # :nodoc:
      @data.read(column.length)
    end

    def get_memo(column) # :nodoc:
      if @memo
        @memo.get(memo_start_block(column))
      else
        # the memo file is missing, so read ahead to next record and return nil
        @data.read(column.length)
        nil
      end
    end

    def init_attribute(column) # :nodoc:
      value = column.memo? ? get_memo(column) : get_data(column)
      column.type_cast(value)
    end

    def memo_start_block(column) # :nodoc:
      data = get_data(column)
      data = data.unpack('V').first if %w[30 31].include?(@version)
      data.to_i
    end

    def method_missing(method, *args) # :nodoc:
      if (index = underscored_column_names.index(method.to_s))
        attributes[@columns[index].name]
      else
        super
      end
    end

    def respond_to_missing?(method, *) # :nodoc:
      underscored_column_names.include?(method.to_s) || super
    end

    def underscored_column_names # :nodoc:
      @underscored_column_names ||= @columns.map(&:underscored_name)
    end
  end
end
