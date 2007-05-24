module DBF
  class Reader
    attr_reader :field_count
    attr_reader :fields
    attr_reader :record_count
    attr_reader :version
    attr_reader :last_updated
    attr_reader :memo_file_format
    attr_reader :memo_block_size
    
    def initialize(file)
      @data_file = File.open(file, 'rb')
      @memo_file = open_memo(file)
      reload!
    end
    
    def reload!
      get_header_info
      get_memo_header_info if @memo_file
      get_field_descriptors
    end
    
    def has_memo_file?
      @memo_file ? true : false
    end
    
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
    
    def field(field_name)
      @fields.detect {|f| f.name == field_name.to_s}
    end
    
    # An array of all the records contained in the database file
    def records
      seek_to_record(0)
      @records ||= Array.new(@record_count) do |i|
        if active_record?
          DBF::Record.new(self, @data_file, @memo_file)
        else
          seek_to_record(i + 1)
          nil
        end
      end
    end
    
    alias_method :rows, :records
    
    # Returns the record at <a>index</i> by seeking to the record in the
    # physical database file. See the documentation for the records method for
    # information on how these two methods differ.
    def record(index)
      seek_to_record(index)
      active_record? ? Record.new(self, @data_file, @memo_file) : nil
    end
    
    alias_method :row, :record
    
    def version_description
      VERSION_DESCRIPTIONS[version]
    end
    
    private
    
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
    
  end
  
  class FieldLengthError < DBFError; end
  class Field
    attr_reader :name, :type, :length, :decimal

    def initialize(name, type, length, decimal)
      raise FieldLengthError, "field length must be greater than 0" unless length > 0
      @name, @type, @length, @decimal = name.gsub(/\0/, ''), type, length, decimal
    end

  end
  
end