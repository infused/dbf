# frozen_string_literal: true

module DBF
  class ColumnBuilder
    def initialize(table, data, version_config, header_length:, record_length:)
      @table = table
      @data = data
      @version_config = version_config
      @header_length = header_length
      # One byte of every record is the deletion flag
      @max_width = record_length - 1
    end

    def build
      safe_seek do
        @data.seek(@version_config.header_size)
        width = 0
        [].tap do |columns|
          until end_of_columns?
            args = @version_config.read_column_args(@table, @data)
            # A descriptor truncated by EOF is returned as nil, or unpacks to
            # a nil length; stop rather than constructing an invalid column
            # (which would crash on nil < 0).
            length = args&.[](3)
            break if length.nil?

            # Columns longer than the record would read into the following
            # records; stop so a crafted file cannot multiply decoding work.
            width += length
            break if width > @max_width

            columns << Column.new(*args)
          end
        end
      end
    end

    private

    # Descriptors live inside the header. Stop at header_length so a
    # crafted file cannot declare thousands of columns over its record area.
    def end_of_columns?
      @data.pos + @version_config.column_layout.first > @header_length || end_of_record?
    end

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
