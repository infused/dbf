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
      @column_names = @columns.map {|column| column.underscored_name}
      define_accessors
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
      @column_names.map {|name| attributes[name]}
    end
    
    # Do all search parameters match?
    #
    # @param [Hash] options
    # @return [Boolean]
    def match?(options)
      options.all? {|key, value| attributes[Util.underscore(key.to_s)] == value}
    end
    
    # @return [Hash]
    def attributes
      @attributes ||= begin
        attributes = Attributes.new
        @columns.each {|column| attributes[column.name] = init_attribute(column)}
        attributes
      end
    end
    
    private
    
    def define_accessors #nodoc
      @column_names.each do |name|
        next if respond_to? name
        self.class.send(:define_method, name) do
          attributes[name]
        end
      end
    end
    
    def init_attribute(column) #nodoc
      if column.memo?
        @memo.get get_memo_start_block(column)
      else
        column.type_cast unpack_data(column)
      end
    end
   
    def get_memo_start_block(column) #nodoc
      if %w(30 31).include?(@version)
        @data.read(column.length).unpack('V').first
      else
        unpack_data(column).to_i
      end
    end

    def unpack_data(column) #nodoc
      @data.read(column.length).unpack("a#{column.length}").first
    end
    
  end
end
