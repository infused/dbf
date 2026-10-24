# frozen_string_literal: true

module DBF
  module Memo
    class Base
      BLOCK_HEADER_SIZE = 8
      BLOCK_SIZE = 512

      def self.open(filename, version, max_size: nil)
        new(FileHandler.open_file(filename), version, max_size:)
      end

      # @param max_size [Integer, nil] bytes to read from each memo; longer
      #   memos are cut off. nil reads every memo in full.
      def initialize(data, version, max_size: nil)
        @data = data
        @version = version
        @max_size = max_size
      end

      def get(start_block)
        return nil unless start_block > 0

        build_memo start_block
      rescue RangeError
        # A corrupt memo pointer too large to seek to has no memo
        nil
      end

      def close
        @data.close && @data.closed?
      end

      def closed?
        @data.closed?
      end

      private

      attr_reader :data, :max_size

      # Bounds a memo length by max_size, when one is set
      def limit(length) # :nodoc:
        max_size && length > max_size ? max_size : length
      end

      def offset(start_block) # :nodoc:
        start_block * block_size
      end

      def content_size(memo_size) # :nodoc:
        (memo_size - block_size) + BLOCK_HEADER_SIZE
      end

      def block_content_size # :nodoc:
        @block_content_size ||= block_size - BLOCK_HEADER_SIZE
      end

      def block_size # :nodoc:
        BLOCK_SIZE
      end
    end
  end
end
