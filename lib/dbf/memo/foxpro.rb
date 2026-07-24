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
        return memo_string[0, memo_size] unless memo_size > block_content_size

        # Bound the read by the bytes remaining so a crafted 32-bit memo_size
        # cannot force a ~4 GiB allocation from a small memo file.
        length = content_size(memo_size)
        remaining = @data.size - @data.pos
        length = remaining if length > remaining
        memo_string << @data.read(length) if length.positive?
        memo_string
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
