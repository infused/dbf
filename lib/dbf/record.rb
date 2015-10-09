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

    # Maps a row to an array of values
    #
    # @return [Array]
    def to_a
      @columns.map { |column| attributes[column.name] }
    end

    # Do all search parameters match?
    #
    # @param [Hash] options
    # @return [Boolean]
    def match?(options)
      options.all? { |key, value| self[key] == value }
    end

    # Reads attributes by column name
    #
    # @param [String, Symbol] key
    def [](name)
      key = name.to_s
      if attributes.key?(key)
        attributes[key]
      elsif (index = underscored_column_names.index(key))
        attributes[@columns[index].name]
      end
    end

    # Record attributes
    #
    # @return [Hash]
    def attributes
      @attributes ||=
        Hash[@columns.map { |column| [column.name, init_attribute(column)] }]
    end

    # Overrides standard Object.respond_to? to return true if a
    # matching column name is found.
    #
    # @param [String, Symbol] method
    # @return [Boolean]
    def respond_to?(method, *args)
      if underscored_column_names.include?(method.to_s)
        true
      else
        super
      end
    end

    private

    def file_offset(attribute_name)
      column = @columns.detect { |c| c.name == attribute_name.to_s }
      index = @columns.index(column)
      @columns[0, index + 1].compact.reduce(0) { |x, c| x += c.length }
    end

    def method_missing(method, *args) # nodoc
      if (index = underscored_column_names.index(method.to_s))
        attributes[@columns[index].name]
      else
        super
      end
    end

    def underscored_column_names # nodoc
      @underscored_column_names ||= @columns.map(&:underscored_name)
    end

    def init_attribute(column) # nodoc
      value = column.memo? ? memo(column) : unpack_data(column)
      column.type_cast(value)
    end

    def memo(column) # nodoc
      if @memo
        @memo.get(memo_start_block(column))
      else
        # the memo file is missing, so read ahead to next record and return nil
        @data.read(column.length)
        nil
      end
    end

    def memo_start_block(column) # nodoc
      format = 'V' if %w(30 31).include?(@version)
      unpack_data(column, format).to_i
    end

    def unpack_data(column, format = nil) # nodoc
      format ||= "a#{column.length}"
      @data.read(column.length).unpack(format).first
    end
  end
end
