# frozen_string_literal: true

module DBF
  module Memo
    # Handler for dBase IV memo files
    class Dbase4 < Base
      MEMO_SIZE_OFFSET = 4
      MEMO_SIZE_FORMAT = 'x4L'

      private

      def build_memo(start_block)
        @data.seek(offset(start_block))
        memo_size = read_memo_size
        @data.read(memo_size)
      end

      def read_memo_size
        @data.read(BLOCK_HEADER_SIZE).unpack1(MEMO_SIZE_FORMAT)
      end
    end
  end
end
