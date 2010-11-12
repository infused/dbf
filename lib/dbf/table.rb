module DBF

  # DBF::Table is the primary interface to a single DBF file and provides 
  # methods for enumerating and searching the records.
  
  # TODO set record_length to length of actual used column lengths
  class Table
    include Enumerable
    
    DBF_HEADER_SIZE = 32
    
    VERSION_DESCRIPTIONS = {
      "02" => "FoxBase",
      "03" => "dBase III without memo file",
      "04" => "dBase IV without memo file",
      "05" => "dBase V without memo file",
      "30" => "Visual FoxPro",
      "31" => "Visual FoxPro with AutoIncrement field",
      "7b" => "dBase IV with memo file",
      "83" => "dBase III with memo file",
      "8b" => "dBase IV with memo file",
      "8e" => "dBase IV with SQL table",
      "f5" => "FoxPro with memo file",
      "fb" => "FoxPro without memo file"
    }
    
    attr_reader :version                # Internal dBase version number
    attr_reader :record_count           # Total number of records
    
    # Opens a DBF::Table
    # Example:
    #   table = DBF::Table.new 'data.dbf'
    #
    # @param [String] path Path to the dbf file
    def initialize(path)
      @data = File.open(path, 'rb')
      get_header_info
      @memo = open_memo(path)
    end
    
    # Closes the table and memo file
    def close
      @memo && @memo.close
      @data.close
    end
    
    # Calls block once for each record in the table. The record may be nil
    # if the record has been marked as deleted.
    #
    # @yield [nil, DBF::Record]
    def each
      @record_count.times {|i| yield record(i)}
    end
    
    # Retrieve a record by index number.
    # The record will be nil if it has been deleted, but not yet pruned from
    # the database.
    #
    # @param [Fixnum] index
    # @return [DBF::Record, NilClass]
    def record(index)
      seek_to_record(index)
      current_record
    end
    
    alias_method :row, :record
    
    # Human readable version description
    #
    # @return [String]
    def version_description
      VERSION_DESCRIPTIONS[version]
    end
    
    # Generate an ActiveRecord::Schema
    # 
    # xBase data types are converted to generic types as follows:
    # - Number columns with no decimals are converted to :integer
    # - Number columns with decimals are converted to :float
    # - Date columns are converted to :datetime
    # - Logical columns are converted to :boolean
    # - Memo columns are converted to :text
    # - Character columns are converted to :string and the :limit option is set
    #   to the length of the character column
    #
    # Example:
    #   create_table "mydata" do |t|
    #     t.column :name, :string, :limit => 30
    #     t.column :last_update, :datetime
    #     t.column :is_active, :boolean
    #     t.column :age, :integer
    #     t.column :notes, :text
    #   end
    #
    # @return [String]
    def schema
      s = "ActiveRecord::Schema.define do\n"
      s << "  create_table \"#{File.basename(@data.path, ".*")}\" do |t|\n"
      columns.each do |column|
        s << "    t.column #{column.schema_definition}"
      end
      s << "  end\nend"        
      s
    end
    
    # Dumps all records to a CSV file.  If no filename is given then CSV is
    # output to STDOUT.
    #
    # @param [optional String] path Defaults to basename of dbf file
    def to_csv(path = nil)
      path = File.basename(@data.path, '.dbf') + '.csv' if path.nil?
      FCSV.open(path, 'w', :force_quotes => true) do |csv|
        csv << columns.map {|c| c.name}
        each {|record| csv << record.to_a}
      end
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
    # The <b>command</b> may be a record index, :all, or :first.
    # <b>options</b> is optional and, if specified, should be a hash where the keys correspond
    # to column names in the database.  The values will be matched exactly with the value
    # in the database.  If you specify more than one key, all values must match in order 
    # for the record to be returned.  The equivalent SQL would be "WHERE key1 = 'value1'
    # AND key2 = 'value2'".
    #
    # @param [Fixnum, Symbol] command
    # @param [optional, Hash] options Hash of search parameters
    # @yield [optional, DBF::Record, NilClass]
    def find(command, options = {}, &block)
      case command
      when Fixnum
        record(command)
      when Array
        command.map {|i| record(i)}
      when :all
        find_all(options, &block)
      when :first
        find_first(options)
      end
    end
    
    # Retrieves column information from the database
    def columns
      return @columns if @columns
      
      @data.seek(DBF_HEADER_SIZE)
      @columns = []
      @column_count.times do
        name, type, length, decimal = @data.read(32).unpack('a10 x a x4 C2')
        @columns << Column.new(name.strip, type, length, decimal) if length > 0
      end
      # Reset the column count in case any were skipped
      @column_count = @columns.size
      @columns
    end
    
    private
    
    def open_memo(path) #nodoc
      %w(fpt FPT dbt DBT).each do |extname|
        filename = path.sub(/#{File.extname(path)[1..-1]}$/, extname)
        if File.exists?(filename)
          return Memo.new(File.open(filename, 'rb'), extname.downcase.to_sym, version)
        end
      end
      nil
    end
    
    def find_all(options) #nodoc
      map do |record|
        if record.try(:match?, options)
          yield record if block_given?
          record
        end
      end.compact
    end
    
    def find_first(options) #nodoc
      each do |record|
        return record if record.try(:match?, options)
      end
      nil
    end
    
    def deleted_record? #nodoc
      @data.read(1).unpack('a') == ['*']
    end
    
    def current_record
      deleted_record? ? nil : DBF::Record.new(@data.read(@record_length), columns, version, @memo)
    end
    
    def get_header_info #nodoc
      @data.rewind
      @version, @record_count, @header_length, @record_length = @data.read(DBF_HEADER_SIZE).unpack('H2 x3 V v2')
      @column_count = (@header_length - DBF_HEADER_SIZE + 1) / DBF_HEADER_SIZE
    end
    
    def seek(offset) #nodoc
      @data.seek @header_length + offset
    end
  
    def seek_to_record(index) #nodoc
      seek index * @record_length
    end
    
  end
  
end