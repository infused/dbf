# frozen_string_literal: true

module DBF
  module Memo
    class Foxpro < Base
      FPT_HEADER_SIZE = 512

      def initialize(data, version)
        @data = data
        super
      end

      def build_memo(start_block) # :nodoc:
        @data.seek offset(start_block)
        memo_type, memo_size, memo_string = @data.read(block_size).unpack('NNa*')
        return nil unless memo_type == 1 && memo_size > 0

        read_memo_content(memo_string, memo_size)
      rescue StandardError
        nil
      end

      private

      def read_memo_content(memo_string, memo_size) # :nodoc:
        if memo_size > block_content_size
          memo_string << @data.read(content_size(memo_size))
        else
          memo_string[0, memo_size]
        end
      end

      def block_size # :nodoc:
        @block_size ||= begin
          @data.rewind
          @data.read(FPT_HEADER_SIZE).unpack1('x6n') || 0
        end
      end
    end
  end
end
