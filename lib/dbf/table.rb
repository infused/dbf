module DBF

  # DBF::Table is the primary interface to a single DBF file and provides 
  # methods for enumerating and searching the records.
  class Table
    DBF_HEADER_SIZE = 32
    FPT_HEADER_SIZE = 512
    
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
    
    attr_reader :column_count           # The total number of columns
    attr_reader :columns                # An array of DBF::Column
    attr_reader :version                # Internal dBase version number
    attr_reader :last_updated           # Last updated datetime
    attr_reader :memo_file_format       # :fpt or :dpt
    attr_reader :memo_block_size        # The block size for memo records
    attr_reader :options                # The options hash used to initialize the table
    attr_reader :data                   # DBF file handle
    attr_reader :memo                   # Memo file handle
    attr_reader :record_count           # Total number of records
    
    # Opens a DBF::Table
    # Example:
    #   table = DBF::Table.new 'data.dbf'
    #
    # @param [String] path Path to the dbf file
    def initialize(path)
      @data = File.open(path, 'rb')
      @memo = open_memo(path)
      reload!
    end
    
    # Closes the table and memo file
    def close
      @data.close
      @memo.close if @memo
    end
    
    # Reloads the database and memo files
    def reload!
      @records = nil
      get_header_info
      get_memo_header_info
      get_column_descriptors
    end
    
    # Checks if there is a memo file
    #
    # @return [Boolean]
    def has_memo_file?
      @memo ? true : false
    end
    
    # Retrieve a Column by name
    # 
    # @param [String, Symbol] column_name 
    # @return [DBF::Column]
    def column(column_name)
      @columns.detect {|f| f.name == column_name.to_s}
    end
    
    # Calls block once for each record in the table. The record may be nil
    # if the record has been marked as deleted.
    #
    # @yield [nil, DBF::Record]
    def each
      0.upto(@record_count - 1) {|index| yield record(index)}
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
    # @param [optional String] path
    # @return [String]
    def schema(path = nil)
      s = "ActiveRecord::Schema.define do\n"
      s << "  create_table \"#{File.basename(@data.path, ".*")}\" do |t|\n"
      columns.each do |column|
        s << "    t.column #{column.schema_definition}"
      end
      s << "  end\nend"
      
      if path
        File.open(path, 'w') {|f| f.puts(s)}
      end
        
      s
    end
    
    def to_a
      records = []
      each {|record| records << record if record}
      records
    end
    
    # Dumps all records to a CSV file.  If no filename is given then CSV is
    # output to STDOUT.
    #
    # @param [optional String] path Defaults to basename of dbf file
    def to_csv(path = nil)
      path = File.basename(@data.path, '.dbf') + '.csv' if path.nil?
      FCSV.open(path, 'w', :force_quotes => true) do |csv|
        csv << columns.map {|c| c.name}
        each do |record|
          csv << record.to_a
        end
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
    
    private
    
    # Find all matching
    #
    # @param [Hash] options
    # @yield [optional DBF::Record]
    # @return [Array]
    def find_all(options, &block)
      results = []
      each do |record|
        if record.try(:match?, options)
          if block_given?
            yield record
          else
            results << record
          end
        end
      end
      results
    end
    
    # Find first matching
    # 
    # @param [Hash] options
    # @return [DBF::Record, nil]
    def find_first(options)
      each do |record|
        return record if record.try(:match?, options)
      end
      nil
    end
    
    # Open memo file
    #
    # @params [String] path
    # @return [File]
    def open_memo(path)
      %w(fpt FPT dbt DBT).each do |extname|
        filename = replace_extname(path, extname)
        if File.exists?(filename)
          @memo_file_format = extname.downcase.to_sym
          return File.open(filename, 'rb')
        end
      end
      nil
    end
    
    # Replace the file extension
    #
    # @param [String] path
    # @param [String] extension
    # @return [String]
    def replace_extname(path, extension)
      path.sub(/#{File.extname(path)[1..-1]}$/, extension)
    end
    
    # Is record marked for deletion
    #
    # @return [Boolean]
    def deleted_record?
      @data.read(1).unpack('a') == ['*']
    end
    
    def current_record
      deleted_record? ? nil : DBF::Record.new(self)
    end
    
    # Determine database version, record count, header length and record length
    def get_header_info
      @data.rewind
      @version, @record_count, @header_length, @record_length = @data.read(DBF_HEADER_SIZE).unpack('H2 x3 V v2')
      @column_count = (@header_length - DBF_HEADER_SIZE + 1) / DBF_HEADER_SIZE
    end
    
    # Retrieves column information from the database
    def get_column_descriptors
      @columns = []
      @column_count.times do
        name, type, length, decimal = @data.read(32).unpack('a10 x a x4 C2')
        if length > 0
          @columns << Column.new(name.strip, type, length, decimal)
        end
      end
      # Reset the column count in case any were skipped
      @column_count = @columns.size
      
      @columns
    end
    
    # Determines the memo block size and next available block
    def get_memo_header_info
      if has_memo_file?
        @memo.rewind
        if @memo_file_format == :fpt
          @memo_next_available_block, @memo_block_size = @memo.read(FPT_HEADER_SIZE).unpack('N x2 n')
          @memo_block_size = 0 if @memo_block_size.nil?
        else
          @memo_block_size = 512
          @memo_next_available_block = File.size(@memo.path) / @memo_block_size
        end
      end
    end
    
    # Seek to a byte offset
    # 
    # @params [Fixnum] offset
    def seek(offset)
      @data.seek(@header_length + offset)
    end
  
    # Seek to a record
    #
    # @param [Fixnum] index
    def seek_to_record(index)
      seek(index * @record_length)
    end
    
  end
  
end