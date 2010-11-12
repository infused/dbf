module DBF
  class Memo
    BLOCK_HEADER_SIZE = 8
    FPT_HEADER_SIZE = 512
    
    attr_reader :format
    attr_reader :data
    
    def initialize(data, format, version)
      @data, @format, @version = data, format.to_sym, version
      get_block_size
    end
    
    def get(start_block)
      send "build_#{format}_memo", start_block if start_block > 0
    end
    
    private
    
    def get_block_size #nodoc
      data.rewind
      if format == :fpt
        @memo_block_size = data.read(FPT_HEADER_SIZE).unpack('x6n').first || 0
      else
        @memo_block_size = 512
      end
    end
    
    def build_fpt_memo(start_block) #nodoc
      data.seek memo_offset(start_block)
      
      memo_type, memo_size, memo_string = data.read(@memo_block_size).unpack("NNa*")
      return nil unless memo_type == 1 && memo_size > 0
      
      if memo_size > memo_block_content_size
        memo_string << data.read(memo_content_size(memo_size))
      else
        memo_string = memo_string[0, memo_size]
      end
      memo_string.strip
    end
    
    def build_dbt_memo(start_block) #nodoc
      data.seek memo_offset(start_block)
      
      case @version
      when "83" # dbase iii
        memo_string = ""
        loop do
          block = data.read(@memo_block_size)
          memo_string << block
          break if block.tr("\000",'').size < @memo_block_size
        end
      when "8b" # dbase iv
        memo_size = data.read(BLOCK_HEADER_SIZE).unpack("x4L").first
        memo_string = data.read(memo_size)
      end
      memo_string
    end
    
    def memo_offset(start_block) #nodoc
      start_block * @memo_block_size
    end

    def memo_content_size(memo_size) #nodoc
      (memo_size - @memo_block_size) + BLOCK_HEADER_SIZE
    end

    def memo_block_content_size #nodoc
      @memo_block_size - BLOCK_HEADER_SIZE
    end
    
  end
end