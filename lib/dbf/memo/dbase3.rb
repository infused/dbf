# frozen_string_literal: true

module DBF
  module Memo
    # Handler for dBase III memo files
    class Dbase3 < Base
      MEMO_TERMINATOR_CHARS = ["\000", "\032"].freeze

      private

      def build_memo(start_block)
        @data.seek(offset(start_block))
        memo_content = []
        
        loop do
          block = clean_memo_block(@data.read(BLOCK_SIZE))
          memo_content << block
          break if block.size < BLOCK_SIZE
        end
        
        memo_content.join
      end

      def clean_memo_block(block)
        block.gsub(/[#{MEMO_TERMINATOR_CHARS.join}]/, '')
      end
    end
  end
end
