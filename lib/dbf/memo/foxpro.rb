# frozen_string_literal: true

module DBF
  module Memo
    # Handler for FoxPro memo files
    class Foxpro < Base
      FPT_HEADER_SIZE = 512
      MEMO_TYPE_TEXT = 1
      BLOCK_SIZE_OFFSET = 6
      BLOCK_SIZE_FORMAT = 'x6n'
      MEMO_HEADER_FORMAT = 'NNa*'

      private

      def build_memo(start_block)
        @data.seek(offset(start_block))
        memo_type, memo_size, memo_string = read_memo_header
        
        return nil unless valid_memo?(memo_type, memo_size)
        
        read_memo_content(memo_size, memo_string)
      rescue StandardError
        nil
      end

      def read_memo_header
        @data.read(block_size).unpack(MEMO_HEADER_FORMAT)
      end

      def valid_memo?(memo_type, memo_size)
        memo_type == MEMO_TYPE_TEXT && memo_size.positive?
      end

      def read_memo_content(memo_size, memo_string)
        if memo_size > block_content_size
          memo_string + @data.read(content_size(memo_size))
        else
          memo_string[0, memo_size]
        end
      end

      def block_size
        @block_size ||= read_block_size_from_header
      end

      def read_block_size_from_header
        @data.rewind
        @data.read(FPT_HEADER_SIZE).unpack1(BLOCK_SIZE_FORMAT) || 0
      end
    end
  end
end
