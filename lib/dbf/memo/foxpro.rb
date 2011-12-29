module DBF
  module Memo
    class Foxpro < Base
      FPT_HEADER_SIZE = 512
      
      def build_memo(start_block) #nodoc
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
      
      private
      
      def block_size #nodoc
        @block_size ||= begin
          @data.rewind
          @data.read(FPT_HEADER_SIZE).unpack('x6n').first || 0
        end
      end
    end
  end
end