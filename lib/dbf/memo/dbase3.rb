# frozen_string_literal: true

module DBF
  module Memo
    class Dbase3 < Base
      def build_memo(start_block) # :nodoc:
        data.seek offset(start_block)
        memo_string = +''
        loop do
          block = data.read(BLOCK_SIZE)
          # A start block past EOF yields nil; return what we have rather
          # than crashing on nil.gsub.
          break if block.nil?

          block = block.gsub(/(\000|\032)/, '')
          memo_string << block
          break if block.size < BLOCK_SIZE
        end
        memo_string
      end
    end
  end
end
