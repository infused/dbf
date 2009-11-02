module DBF
  
  class EnumTable < Table
    include Enumerable
    
    def each
      0.upto(@record_count - 1) do |n|
        seek_to_record(n)
        unless deleted_record?
          yield DBF::Record.new(self)
        end
      end
    end
    
    # An array of all the records contained in the database file.  Each record is an instance
    # of DBF::Record (or nil if the record is marked for deletion).
    def records
      self.to_a
    end
    
    # Returns a DBF::Record (or nil if the record has been marked for deletion) for the record at <tt>index</tt>.
    def record(index)
      records[index]
    end
    
    # Find records using a simple ActiveRecord-like syntax.
    #
    # Examples:
    #   table = DBF::Table.new 'mydata.dbf'
    #   
    #   # Find record number 5
    #   table.find(5)
    #
    #   # Find all records for Keith Morrison
    #   table.find :all, :first_name => "Keith", :last_name => "Morrison"
    # 
    #   # Find first record
    #   table.find :first, :first_name => "Keith"
    #
    # The <b>command</b> can be an id, :all, or :first.
    # <b>options</b> is optional and, if specified, should be a hash where the keys correspond
    # to column names in the database.  The values will be matched exactly with the value
    # in the database.  If you specify more than one key, all values must match in order 
    # for the record to be returned.  The equivalent SQL would be "WHERE key1 = 'value1'
    # AND key2 = 'value2'".
    def find(command, options = {})
      results = options.empty? ? records : records.select {|record| all_values_match?(record, options)}
      
      case command
      when Fixnum
        record(command)
      when :all
        results
      when :first
        results.first
      end
    end
    
  end
  
end