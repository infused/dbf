module DBF
  # An instance of DBF::Record represents a row in the DBF file 
  class Record
    # Initialize a new DBF::Record
    # 
    # @param [DBF::Table] table
    def initialize(data, columns, version, memo)
      @data, @columns, @version, @memo = StringIO.new(data), columns, version, memo
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
      @columns.map { |column| attributes[Util.underscore(column.name)] }
    end
    
    # Do all search parameters match?
    #
    # @param [Hash] options
    # @return [Boolean]
    def match?(options)
      options.all? {|key, value| attributes[Util.underscore(key.to_s)] == value}
    end
    
    def attributes
      return @attributes if @attributes
      
      @attributes = Attributes.new
      @columns.each do |column|
        @attributes[column.name] = init_attribute(column)
      end
      @attributes
    end
    
    private
    
    def define_accessors #nodoc
      @columns.each do |column|
        unless self.class.method_defined? column.underscored_name
          self.class.class_eval <<-END
            def #{column.underscored_name}
              @#{column.underscored_name} ||= attributes['#{column.underscored_name}']
            end
          END
        end
      end
    end
    
    def init_attribute(column) #nodoc
      column.memo? ? @memo.get(get_memo_start_block(column)) : column.type_cast(unpack_data(column))
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