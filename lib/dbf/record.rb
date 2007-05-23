module DBF
  class Record < Hash
    def initialize(reader, data_file, memo_file)
      @reader, @data_file, @memo_file = reader, data_file, memo_file
      reader.fields.each do |field| 
        case field.type
        when 'N' # number
          self[field.name] = field.decimal == 0 ? unpack_string(field).to_i : unpack_string(field).to_f
        when 'D' # date
          raw = unpack_string(field).strip
          unless raw.empty?
            begin
              self[field.name] = Time.gm(*raw.match(DATE_REGEXP).to_a.slice(1,3).map {|n| n.to_i})
            rescue
              self[field.name] = Date.new(*raw.match(DATE_REGEXP).to_a.slice(1,3).map {|n| n.to_i})
            end
          end
        when 'M' # memo
          starting_block = unpack_string(field).to_i
          self[field.name] = read_memo(starting_block)
        when 'L' # logical
          self[field.name] = unpack_string(field) =~ /^(y|t)$/i ? true : false
        else
          self[field.name] = unpack_string(field)
        end
      end
      self
    end
    
    def unpack_field(field)
      @data_file.read(field.length).unpack("a#{field.length}")
    end
    
    def unpack_string(field)
      unpack_field(field).to_s
    end
    
    def read_memo(start_block)
      return nil if start_block == 0
      @memo_file.seek(start_block * @reader.memo_block_size)
      if @reader.memo_file_format == :fpt
        memo_type, memo_size, memo_string = @memo_file.read(@reader.memo_block_size).unpack("NNa56")
        
        memo_block_content_size = @reader.memo_block_size - FPT_BLOCK_HEADER_SIZE
        if memo_size > memo_block_content_size
          memo_string << @memo_file.read(memo_size - @reader.memo_block_size + FPT_BLOCK_HEADER_SIZE)
        elsif memo_size > 0 and memo_size < memo_block_content_size
          memo_string = memo_string[0, memo_size]
        end
      else
        case @reader.version
        when "83" # dbase iii
          memo_string = ""
          loop do
            memo_string << block = @memo_file.read(512)
            break if block.strip.size < 512
          end
        when "8b" # dbase iv
          memo_type, memo_size = @memo_file.read(8).unpack("LL")
          memo_string = @memo_file.read(memo_size)
        end
      end
      memo_string
    end
  end
end