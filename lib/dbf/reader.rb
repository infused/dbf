module DBF
  class Reader
    # The total number of fields (columns)
    attr_reader :field_count
    # An array of DBF::Field records
    attr_reader :fields
    # The total number of records.  This number includes any deleted records.
    attr_reader :record_count
    # Internal dBase version number
    attr_reader :version
    # Last updated datetime
    attr_reader :last_updated
    # Either :fpt or :dpt
    attr_reader :memo_file_format
    # The block size for memo records
    attr_reader :memo_block_size
    
    # Initialize a new DBF::Reader.
    # Example:
    #   reader = DBF::Reader.new 'data.dbf'
    def initialize(filename)
      @in_memory = true
      @data_file = File.open(filename, 'rb')
      @memo_file = open_memo(filename)
      reload!
    end
    
    # Reloads the database and memo files
    def reload!
      @records = nil
      get_header_info
      get_memo_header_info if @memo_file
      get_field_descriptors
    end
    
    # Returns true if there is a corresponding memo file
    def has_memo_file?
      @memo_file ? true : false
    end
    
    # If true, DBF::Reader will load all records into memory.  If false, records are retrieved using file I/O.
    def in_memory?
      @in_memory
    end
    
    # Tells DBF::Reader whether to load all records into memory.  Defaults to true.
    # You may need to set this to false if the database is very large in order to reduce memory usage.
    def in_memory=(boolean)
      @in_memory = boolean
    end
    
    def field(field_name)
      @fields.detect {|f| f.name == field_name.to_s}
    end
    
    # An array of all the records contained in the database file
    def records
      if in_memory?
        @records ||= get_all_records_from_file
      else
        get_all_records_from_file
      end
    end
    
    alias_method :rows, :records
    
    # Returns the record at <tt>index</tt>.
    def record(index)
      if in_memory?
        records[index]
      else
        get_record_from_file(index)
      end
    end
    
    # Find records.  Examples:
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
    def find(command, options = {})
      case command
      when Fixnum
        record(command)
      when :all
        records.select do |record|
          options.map {|key, value| record[key.to_s] == value}.all?
        end
      when :first
        return records.first
        records.detect do |record|
          options.map {|key, value| record[key.to_s] == value}.all?
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
    # - Number fields are converted to :integer if there are no decimals, otherwise
    #   they are converted to :float
    # - Date fields are converted to :datetime
    # - Logical fields are converted to :boolean
    # - Memo fields are converted to :text
    # - Character fields are converted to :string and the :limit option is set
    #   to the length of the character field
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
      s << "  create_table \"#{File.basename(@data_file.path, ".*")}\" do |t|\n"
      fields.each do |field|
        s << "    t.column \"#{field.name}\""
        case field.type
        when "N" # number
          if field.decimal > 0
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
          s << ", :string, :limit => #{field.length}"
        end
        s << "\n"
      end
      s << "  end\nend"
      
      if path
        return File.open(path, 'w') {|f| f.puts(s)}
      else
       return s
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
    
      # Returns false if the record has been marked as deleted, otherwise it returns true. When dBase records are deleted a
      # flag is set, marking the record as deleted. The record will not be fully removed until the database has been compacted.
      def active_record?
        @data_file.read(1).unpack('H2').to_s == '20'
      rescue
        false
      end
    
      def get_header_info
        @data_file.rewind
        @version, @record_count, @header_length, @record_length = @data_file.read(DBF_HEADER_SIZE).unpack('H2xxxVvv')
        @field_count = (@header_length - DBF_HEADER_SIZE + 1) / DBF_HEADER_SIZE
      end
    
      def get_field_descriptors
        @fields = []
        @field_count.times do
          name, type, length, decimal = @data_file.read(32).unpack('a10xax4CC')
          if length > 0 && !name.strip.empty?
            @fields << Field.new(name, type, length, decimal)
          end
        end
        # adjust field count
        @field_count = @fields.size
        @fields
      end
    
      def get_memo_header_info
        @memo_file.rewind
        if @memo_file_format == :fpt
          @memo_next_available_block, @memo_block_size = @memo_file.read(FPT_HEADER_SIZE).unpack('Nxxn')
        else
          @memo_block_size = 512
          @memo_next_available_block = File.size(@memo_file.path) / @memo_block_size
        end
      end
    
      def seek(offset)
        @data_file.seek(@header_length + offset)
      end
    
      def seek_to_record(index)
        seek(index * @record_length)
      end
      
      # Returns the record at <tt>index</tt> by seeking to the record in the
      # physical database file. See the documentation for the records method for
      # information on how these two methods differ.
      def get_record_from_file(index)
        seek_to_record(index)
        active_record? ? Record.new(self, @data_file, @memo_file) : nil
      end
      
      def get_all_records_from_file
        seek_to_record(0)
        Array.new(@record_count) do |i|
          active_record? ? DBF::Record.new(self, @data_file, @memo_file) : nil
        end
      end
    
  end
  
end