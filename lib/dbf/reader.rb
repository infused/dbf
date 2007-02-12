module DBF
  
  DBF_HEADER_SIZE = 32
  FPT_HEADER_SIZE = 512
  FPT_BLOCK_HEADER_SIZE = 8
  DATE_REGEXP = /([\d]{4})([\d]{2})([\d]{2})/
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
    
  class DBFError < StandardError; end
  class UnpackError < DBFError; end
  
  class Reader
    attr_reader :field_count
    attr_reader :fields
    attr_reader :record_count
    attr_reader :version
    attr_reader :last_updated
    attr_reader :memo_file_format
    
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
        filename = file.sub(/dbf$/i, extension)
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
    
    def memo(start_block)
      @memo_file.rewind
      @memo_file.seek(start_block * @memo_block_size)
      if @memo_file_format == :fpt
        memo_type, memo_size, memo_string = @memo_file.read(@memo_block_size).unpack("NNa56")
        if memo_size > @memo_block_size - FPT_BLOCK_HEADER_SIZE
          memo_string << @memo_file.read(memo_size - @memo_block_size + FPT_BLOCK_HEADER_SIZE)
        end
      else
        if version == "83" # dbase iii
          memo_string = ""
          loop do
            memo_string << block = @memo_file.read(512)
            break if block.strip.size < 512
          end
        elsif version == "8b" # dbase iv
          memo_type, memo_size = @memo_file.read(8).unpack("LL")
          memo_string = @memo_file.read(memo_size)
        end
      end
      memo_string
    end
    
    # An array of all the records contained in the database file
    def records
      seek_to_record(0)
      @records ||= Array.new(@record_count) do |i|
        if active_record?
          build_record
        else
          seek_to_record(i + 1)
          nil
        end
      end
    end
    
    alias_method :rows, :records
    
    # Jump to record
    def record(index)
      seek_to_record(index)
      active_record? ? build_record : nil
    end
    
    alias_method :row, :record
    
    def version_description
      VERSION_DESCRIPTIONS[version]
    end
    
    private
    
    def active_record?
      @data_file.read(1).unpack('H2').to_s == '20'
    rescue
      false
    end
    
    def build_record
      record = Record.new
      @fields.each do |field| 
        case field.type
        when 'N' # number
          record[field.name] = field.decimal == 0 ? unpack_integer(field) : unpack_float(field) rescue nil
        when 'D' # date
          raw = unpack_string(field).to_s.strip
          unless raw.empty?
            begin
              record[field.name] = Time.gm(*raw.match(DATE_REGEXP).to_a.slice(1,3).map {|n| n.to_i})
            rescue
              record[field.name] = Date.new(*raw.match(DATE_REGEXP).to_a.slice(1,3).map {|n| n.to_i}) rescue nil
            end
          end
        when 'M' # memo
          starting_block = unpack_integer(field)
          record[field.name] = starting_block == 0 ? nil : memo(starting_block) rescue nil
        when 'L' # logical
          record[field.name] = unpack_string(field) =~ /^(y|t)$/i ? true : false rescue false
        else
          record[field.name] = unpack_string(field)
        end
      end
      record
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
          @fields << Field.new(name.strip, type, length, decimal)
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
      seek(@record_length * index)
    end
    
    def unpack_field(field)
      @data_file.read(field.length).unpack("a#{field.length}")
    end
    
    def unpack_string(field)
      unpack_field(field).to_s
    end
    
    def unpack_integer(field)
      unpack_string(field).to_i
    end
    
    def unpack_float(field)
      unpack_string(field).to_f
    end
    
  end
  
  class FieldError < StandardError; end
  
  class Field
    attr_accessor :type, :length, :decimal

    def initialize(name, type, length, decimal)
      raise FieldError, "field length must be greater than 0" unless length > 0
      self.name, self.type, self.length, self.decimal = name, type, length, decimal
    end

    def name=(name)
      @name = name.gsub(/\0/, '')
    end
    
    def name
      @name
    end
  end
  
  class Record < Hash
  end

end
