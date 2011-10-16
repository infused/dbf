module DBF
  class Memo
    BLOCK_HEADER_SIZE = 8
    FPT_HEADER_SIZE = 512
    
    def self.open(filename, version)
      self.new File.open(filename, 'rb'), version
    end
    
    def initialize(data, version)
      @data, @version = data, version
    end
    
    def format
      File.extname(@data.path)        
    end
    
    def get(start_block)
      if start_block > 0
        if format_fpt?
          build_fpt_memo start_block 
        else
          build_dbt_memo start_block
        end
      end
    end
    
    def close
      @data.close
    end
    
    private
    
    def format_fpt? #nodoc
      File.extname(@data.path) =~ /fpt/i
    end
    
    def build_fpt_memo(start_block) #nodoc
      @data.seek offset(start_block)
      
      memo_type, memo_size, memo_string = @data.read(block_size).unpack("NNa*")
      return nil unless memo_type == 1 && memo_size > 0
      
      if memo_size > block_content_size
        memo_string << @data.read(content_size(memo_size))
      else
        memo_string = memo_string[0, memo_size]
      end
      memo_string
    end
    
    def build_dbt_memo(start_block) #nodoc
      case @version
      when "83" # dbase iii
        build_dbt_83_memo(start_block)
      when "8b" # dbase iv
        build_dbt_8b_memo(start_block)
      else
        nil
      end
    end
    
    def build_dbt_83_memo(start_block) #nodoc
      @data.seek offset(start_block)
      memo_string = ""
      begin
        block = @data.read(block_size).gsub(/(\000|\032)/, '')
        memo_string << block
      end until block.size < block_size
      memo_string
    end
    
    def build_dbt_8b_memo(start_block) #nodoc
      @data.seek offset(start_block)
      @data.read(@data.read(BLOCK_HEADER_SIZE).unpack("x4L").first)
    end
    
    def offset(start_block) #nodoc
      start_block * block_size
    end

    def content_size(memo_size) #nodoc
      (memo_size - block_size) + BLOCK_HEADER_SIZE
    end

    def block_content_size #nodoc
      @block_content_size ||= block_size - BLOCK_HEADER_SIZE
    end
    
    def block_size #nodoc
      @block_size ||= begin
        @data.rewind
        format_fpt? ? @data.read(FPT_HEADER_SIZE).unpack('x6n').first || 0 : 512
      end
    end
    
  end
end