# frozen_string_literal: true

module DBF
  module Memo
    class Dbase4 < Base
      def build_memo(start_block) # :nodoc:
        data.seek offset(start_block)

        # A start block past EOF yields a nil/short header; return nil rather
        # than crashing on nil.unpack1.
        header = data.read(BLOCK_HEADER_SIZE)
        return nil unless header && header.bytesize == BLOCK_HEADER_SIZE

        length = header.unpack1('x4L')

        # Bound the read by the bytes remaining so a crafted 32-bit length
        # field cannot force a ~4 GiB allocation from a small memo file.
        remaining = data.size - data.pos
        length = remaining if length > remaining
        return nil if length <= 0

        data.read(length)
      end
    end
  end
end
