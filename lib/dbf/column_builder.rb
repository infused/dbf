# frozen_string_literal: true

module DBF
  class ColumnBuilder
    def initialize(table, data, version_config)
      @table = table
      @data = data
      @version_config = version_config
    end

    def build
      safe_seek do
        @data.seek(@version_config.header_size)
        [].tap do |columns|
          columns << Column.new(*@version_config.read_column_args(@table, @data)) until end_of_record?
        end
      end
    end

    private

    def end_of_record?
      safe_seek do
        byte = @data.read(1)
        # A truncated file that ends before the 0x0D column terminator marks
        # the end of the column list rather than crashing on nil.ord.
        byte.nil? || byte.ord == 13
      end
    end

    def safe_seek
      original_pos = @data.pos
      yield.tap { @data.seek(original_pos) }
    end
  end
end
