# frozen_string_literal: true

module DBF
  class ColumnBuilder
    def initialize(table, data, version_config)
      @table = table
      @data = data
      @version_config = version_config
      @header_length = table.header_length
      @record_length = table.record_length
    end

    def build
      safe_seek do
        @data.seek(@version_config.header_size)
        width = 0
        # One byte of every record is the deletion flag
        max_width = @record_length - 1
        [].tap do |columns|
          until end_of_record?
            count = columns.size
            # Descriptors live inside the header. Stop at header_length so a
            # crafted file cannot declare thousands of columns over its
            # record area.
            if past_header?
              warn_ignored(count, "header length of #{@header_length}")
              break
            end

            args = @version_config.read_column_args(@table, @data)
            # A descriptor truncated by EOF is returned as nil; stop rather
            # than constructing an invalid column.
            break unless args

            # Columns longer than the record would read into the following
            # records; stop so a crafted file cannot multiply decoding work.
            # Zero-length columns take no record bytes, so also allow at most
            # one column per record byte.
            width += args[3]
            if width > max_width || count >= max_width
              warn_ignored(count, "record length of #{@record_length}")
              break
            end

            columns << Column.new(*args)
          end
        end
      end
    end

    private

    def past_header?
      @data.pos + @version_config.column_layout.first > @header_length
    end

    # Columns that do not fit are dropped rather than read, so say so: a file
    # written with a wrong header or record length would otherwise lose
    # columns silently. The message holds no text from the file, so a
    # crafted column name cannot inject lines into a log.
    def warn_ignored(kept, limit)
      warn "DBF: ignored the columns after the first #{kept}: they do not fit within the #{limit} bytes"
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
