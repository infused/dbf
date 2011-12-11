module DBF
  module Memo
    class Base
      BLOCK_HEADER_SIZE = 8
    
      def self.open(filename, version)
        self.new File.open(filename, 'rb'), version
      end
    
      def initialize(data, version)
        @data, @version = data, version
      end
    
      def get(start_block)
        if start_block > 0
          build_memo start_block 
        end
      end
    
      def close
        @data.close
      end
    
      private
    
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
        512
      end
    end
  end
end