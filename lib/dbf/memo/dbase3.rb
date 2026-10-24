# frozen_string_literal: true

module DBF
  module Memo
    class Dbase3 < Base
      # Memo text up to, and whether it reached, the 0x1A terminator
      TERMINATOR_PATTERN = /\A([^\x1A]*)(\x1A)?/n

      def build_memo(start_block) # :nodoc:
        data.seek offset(start_block)
        memo_string = +''
        loop do
          block = data.read(BLOCK_SIZE)
          # A start block past EOF yields nil; return what we have rather
          # than crashing on nil.gsub.
          break if block.nil?

          # The memo ends at its 0x1A terminator; bytes after it in the same
          # block are leftovers, not memo text.
          text, terminated = TERMINATOR_PATTERN.match(block).captures
          text = text.delete("\000")
          memo_string << text
          break if terminated || text.size < BLOCK_SIZE || full?(memo_string)
        end
        memo_string.byteslice(0, limit(memo_string.bytesize))
      end

      private

      # A memo with no terminator runs to the end of the file, so stop
      # reading blocks once max_size bytes have been read.
      def full?(memo_string) # :nodoc:
        max_size && memo_string.bytesize >= max_size
      end
    end
  end
end
