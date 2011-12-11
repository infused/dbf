module DBF
  module Memo
    class Dbase3 < Base
      def build_memo(start_block) #nodoc
        @data.seek offset(start_block)
        memo_string = ""
        begin
          block = @data.read(block_size).gsub(/(\000|\032)/, '')
          memo_string << block
        end until block.size < block_size
        memo_string
      end
    end
  end
end