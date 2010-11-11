module DBF
  # An instance of DBF::Record represents a row in the DBF file 
  class Record
    attr_reader :table
    attr_reader :attributes
    attr_reader :columns
    
    # Initialize a new DBF::Record
    # 
    # @param [DBF::Table] table
    def initialize(data, columns, version, memo)
      @data, @columns, @version, @memo = data, columns, version, memo
      initialize_values
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
      columns.map { |column| attributes[column.name.underscore] }
    end
    
    # Do all search parameters match?
    #
    # @param [Hash] options
    # @return [Boolean]
    def match?(options)
      options.all? {|key, value| attributes[key.to_s.underscore] == value}
    end
    
    private
    
    # Defined attribute accessor methods
    def define_accessors
      columns.each do |column|
        unless self.class.method_defined?(column.name.underscore)
          self.class.send :define_method, column.name.underscore do
            attributes[column.name.underscore]
          end
        end
      end
    end
    
    # Initialize values for a row
    def initialize_values
      @attributes = columns.inject(Attributes.new) do |hash, column|
        if column.memo?
          hash[column.name] = @memo.get(get_starting_block(column))
        else
          hash[column.name] = column.type_cast(unpack_data(column.length))
        end
        hash
      end
    end
   
    # Unpack starting block from database
    #
    # @param [Fixnum] length
    def get_starting_block(column)
      if %w(30 31).include?(@version)
        @data.read(column.length).unpack('V')[0]
      else
        unpack_data(column.length).to_i
      end
    end

    # Unpack raw data from database
    # 
    # @param [Fixnum] length
    def unpack_data(length)
      @data.read(length).unpack("a#{length}").first
    end
    
  end
end