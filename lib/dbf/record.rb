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
      @columns, @version, @memo = columns, version, memo
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
      @columns.map {|column| attributes[column.name]}
    end

    # Do all search parameters match?
    #
    # @param [Hash] options
    # @return [Boolean]
    def match?(options)
      options.all? {|key, value| self[key] == value}
    end

    # Reads attributes by column name
    def [](key)
      key = key.to_s
      if attributes.has_key?(key)
        attributes[key]
      elsif index = column_names.index(key)
        attributes[@columns[index].name]
      end
    end

    # @return [Hash]
    def attributes
      @attributes ||= Hash[@columns.map {|column| [column.name, init_attribute(column)]}]
    end

    def respond_to?(method, *args)
      if column_names.include?(method.to_s)
        true
      else
        super
      end
    end

    def method_missing(method, *args)
      if index = column_names.index(method.to_s)
        attributes[@columns[index].name]
      else
        super
      end
    end

    private

    def column_names
      @column_names ||= @columns.map {|column| column.underscored_name}
    end

    def init_attribute(column) #nodoc
      value = if column.memo?
        @memo && @memo.get(memo_start_block(column))
      else
        unpack_data(column)
      end
      column.type_cast(value)
    end

    def memo_start_block(column) #nodoc
      format = 'V' if %w(30 31).include?(@version)
      unpack_data(column, format).to_i
    end

    def unpack_data(column, format=nil) #nodoc
      format ||= "a#{column.length}"
      @data.read(column.length).unpack(format).first
    end

  end
end
