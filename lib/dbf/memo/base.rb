# frozen_string_literal: true

module DBF
  module Memo
    # Base class for DBF memo file handling
    class Base
      BLOCK_HEADER_SIZE = 8
      BLOCK_SIZE = 512

      # Opens a memo file with specified version
      # @param filename [String] path to the memo file
      # @param version [Symbol] memo file version
      # @return [Base] memo file handler instance
      def self.open(filename, version)
        raise ArgumentError, 'Filename cannot be nil' if filename.nil?
        new(File.open(filename, 'rb'), version)
      end

      def initialize(data, version)
        @data = data
        @version = version
      end

      # Retrieves memo content from specified block
      # @param start_block [Integer] starting block number
      # @return [String, nil] memo content or nil if invalid block
      def get(start_block)
        return nil unless start_block.positive?
        build_memo(start_block)
      end

      def close
        @data.close && @data.closed?
      end

      def closed?
        @data.closed?
      end

      private

      def offset(start_block)
        start_block * block_size
      end

      def content_size(memo_size)
        (memo_size - block_size) + BLOCK_HEADER_SIZE
      end

      def block_content_size
        @block_content_size ||= block_size - BLOCK_HEADER_SIZE
      end

      def block_size
        BLOCK_SIZE
      end
    end
  end
end
