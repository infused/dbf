# frozen_string_literal: true

module DBF
  module Memo
    class Dbase4 < Base
      def build_memo(start_block) # :nodoc:
        @data.seek offset(start_block)
        @data.read(@data.read(BLOCK_HEADER_SIZE).unpack1('x4L'))
      end
    end
  end
end
