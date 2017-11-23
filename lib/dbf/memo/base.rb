module DBF
  module Memo
    class Base
      BLOCK_HEADER_SIZE = 8
      BLOCK_SIZE = 512

      def self.open(filename, version)
        new(File.open(filename, 'rb'), version)
      end

      def initialize(data, version)
        @data = data
        @version = version
      end

      def get(start_block)
        return nil unless start_block > 0
        build_memo start_block
      end

      def close
        @data.close && @data.closed?
      end

      def closed?
        @data.closed?
      end

      private

      def offset(start_block) # :nodoc:
        start_block * block_size
      end

      def content_size(memo_size) # :nodoc:
        (memo_size - block_size) + BLOCK_HEADER_SIZE
      end

      def block_content_size # :nodoc:
        @block_content_size ||= block_size - BLOCK_HEADER_SIZE
      end

      def block_size # :nodoc:
        BLOCK_SIZE
      end
    end
  end
end
