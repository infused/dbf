module DBF
  module Memo
    class Dbase4 < Base
      def build_memo(start_block) #nodoc
        @data.seek offset(start_block)
        @data.read(@data.read(BLOCK_HEADER_SIZE).unpack("x4L").first)
      end
    end
  end
end
