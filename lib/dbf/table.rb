module DBF

  class Table
    # The total number of columns (columns)
    attr_reader :column_count
    
    # An array of DBF::Column records
    attr_reader :columns
    
    # Internal dBase version number
    attr_reader :version
    
    # Last updated datetime
    attr_reader :last_updated
    
    # Either :fpt or :dpt
    attr_reader :memo_file_format
    
    # The block size for memo records
    attr_reader :memo_block_size
    
    # The options that were used when initializing DBF::Table.  This is a Hash.
    attr_reader :options
    
    attr_reader :data
    attr_reader :memo
    
    # Initialize a new DBF::Reader.
    # Example:
    #   reader = DBF::Reader.new 'data.dbf'
    def initialize(filename, options = {})
      @options = {:in_memory => true, :accessors => true}.merge(options)
      
      @in_memory = @options[:in_memory]
      @accessors = @options[:accessors]
      @data = File.open(filename, 'rb')
      @memo = open_memo(filename)
      reload!
    end
    
    # Reloads the database and memo files
    def reload!
      @records = nil
      get_header_info
      get_memo_header_info if @memo
      get_column_descriptors
      build_db_index
    end
    
    # Returns true if there is a corresponding memo file
    def has_memo_file?
      @memo ? true : false
    end
    
    # The total number of active records.
    def record_count
      @db_index.size
    end
    
    # Returns an instance of DBF::Column for <b>column_name</b>.  <b>column_name</b>
    # can be a symbol or a string.
    def column(column_name)
      @columns.detect {|f| f.name == column_name.to_s}
    end
    
    # An array of all the records contained in the database file.  Each record is an instance
    # of DBF::Record (or nil if the record is marked for deletion).
    def records
      if options[:in_memory]
        @records ||= get_all_records_from_file
      else
        get_all_records_from_file
      end
    end
    
    alias_method :rows, :records
    
    # Returns a DBF::Record (or nil if the record has been marked for deletion) for the record at <tt>index</tt>.
    def record(index)
      if options[:in_memory]
        records[index]
      else
        get_record_from_file(index)
      end
    end
    
    # Find records using a simple ActiveRecord-like syntax.
    #
    # Examples:
    #   reader = DBF::Reader.new 'mydata.dbf'
    #   
    #   # Find record number 5
    #   reader.find(5)
    #
    #   # Find all records for Keith Morrison
    #   reader.find :all, :first_name => "Keith", :last_name => "Morrison"
    # 
    #   # Find first record
    #   reader.find :first, :first_name => "Keith"
    #
    # The <b>command</b> can be an id, :all, or :first.
    # <b>options</b> is optional and, if specified, should be a hash where the keys correspond
    # to column names in the database.  The values will be matched exactly with the value
    # in the database.  If you specify more than one key, all values must match in order 
    # for the record to be returned.  The equivalent SQL would be "WHERE key1 = 'value1'
    # AND key2 = 'value2'".
    def find(command, options = {})
      case command
      when Fixnum
        record(command)
      when :all
        return records if options.empty?
        records.select do |record|
          options.map {|key, value| record.attributes[key.to_s] == value}.all?
        end
      when :first
        return records.first if options.empty?
        records.detect do |record|
          options.map {|key, value| record.attributes[key.to_s] == value}.all?
        end
      end
    end
    
    alias_method :row, :record
    
    # Returns a description of the current database file.
    def version_description
      VERSION_DESCRIPTIONS[version]
    end
    
    # Returns a database schema in the portable ActiveRecord::Schema format.
    # 
    # xBase data types are converted to generic types as follows:
    # - Number columns are converted to :integer if there are no decimals, otherwise
    #   they are converted to :float
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
    def schema(path = nil)
      s = "ActiveRecord::Schema.define do\n"
      s << "  create_table \"#{File.basename(@data.path, ".*")}\" do |t|\n"
      columns.each do |column|
        s << "    t.column \"#{underscore(column.name)}\""
        case column.type
        when "N" # number
          if column.decimal > 0
            s << ", :float"
          else
            s << ", :integer"
          end
        when "D" # date
          s << ", :datetime"
        when "L" # boolean
          s << ", :boolean"
        when "M" # memo
          s << ", :text"
        else
          s << ", :string, :limit => #{column.length}"
        end
        s << "\n"
      end
      s << "  end\nend"
      
      if path
        File.open(path, 'w') {|f| f.puts(s)}
      else
        s
      end
    end
    
    private
    
      def open_memo(file)
        %w(fpt FPT dbt DBT).each do |extension|
          filename = file.sub(/#{File.extname(file)[1..-1]}$/, extension)
          if File.exists?(filename)
            @memo_file_format = extension.downcase.to_sym
            return File.open(filename, 'rb')
          end
        end
        nil
      end
    
      def deleted_record?
        @data.read(1).unpack('a') == ['*']
      end
    
      def get_header_info
        @data.rewind
        @version, @record_count, @header_length, @record_length = @data.read(DBF_HEADER_SIZE).unpack('H2 x3 V v2')
        @column_count = (@header_length - DBF_HEADER_SIZE + 1) / DBF_HEADER_SIZE
      end
    
      def get_column_descriptors
        @columns = []
        @column_count.times do
          name, type, length, decimal = @data.read(32).unpack('a10 x a x4 C2')
          if length > 0 && name.strip.any?
            @columns << Column.new(name, type, length, decimal)
          end
        end
        # Reset the column count
        @column_count = @columns.size
        
        @columns
      end
    
      def get_memo_header_info
        @memo.rewind
        if @memo_file_format == :fpt
          @memo_next_available_block, @memo_block_size = @memo.read(FPT_HEADER_SIZE).unpack('N x2 n')
        else
          @memo_block_size = 512
          @memo_next_available_block = File.size(@memo.path) / @memo_block_size
        end
      end
    
      def seek(offset)
        @data.seek(@header_length + offset)
      end
    
      def seek_to_record(index)
        seek(index * @record_length)
      end
      
      # Returns the record at <tt>index</tt> by seeking to the record in the
      # physical database file. See the documentation for the records method for
      # information on how these two methods differ.
      def get_record_from_file(index)
        seek_to_record(@db_index[index])
        deleted_record? ? nil : Record.new(self)
      end
      
      def get_all_records_from_file
        all_records = []
        0.upto(@record_count - 1) do |n|
          seek_to_record(n)
          all_records << DBF::Record.new(self) unless deleted_record?
        end
        all_records
      end
    
      def build_db_index
        @db_index = []
        @deleted_records = []
        0.upto(@record_count - 1) do |n|
          seek_to_record(n)
          if deleted_record?
            @deleted_records << n
          else
            @db_index << n
          end
        end
      end
      
      def underscore(camel_cased_word)
        camel_cased_word.to_s.gsub(/::/, '/').
          gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
          gsub(/([a-z\d])([A-Z])/,'\1_\2').
          tr("-", "_").
          downcase
      end
  end
  
end