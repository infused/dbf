module DBF
  module Memo
    class Dbase3 < Base
      def build_memo(start_block) # nodoc
        @data.seek offset(start_block)
        memo_string = ''
        loop do
          block = @data.read(BLOCK_SIZE).gsub(/(\000|\032)/, '')
          memo_string << block
          break if block.size < BLOCK_SIZE
        end
        memo_string
      end
    end
  end
end
