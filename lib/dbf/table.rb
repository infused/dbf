# frozen_string_literal: true

module DBF
  # Leading bytes that make a spreadsheet treat a CSV cell as a formula:
  # "=", "+", "-", "@", tab, and carriage return.
  CSV_FORMULA_TRIGGERS = [0x3D, 0x2B, 0x2D, 0x40, 0x09, 0x0D].freeze

  # DBF::Table is the primary interface to a single DBF file and provides
  # methods for enumerating and searching the records.
  class Table
    extend Forwardable
    include Enumerable
    include ::DBF::Schema
    include ::DBF::Find

    attr_reader :encoding

    def_delegator :header, :header_length
    def_delegator :header, :record_count
    def_delegator :header, :record_length
    def_delegator :header, :version

    # Opens a DBF::Table
    # Examples:
    #   # working with a file stored on the filesystem
    #   table = DBF::Table.new 'data.dbf'
    #
    #   # working with a misnamed memo file
    #   table = DBF::Table.new 'data.dbf', 'memo.dbt'
    #
    #   # working with a dbf in memory
    #   table = DBF::Table.new StringIO.new(dbf_data)
    #
    #   # working with an open IO object
    #   table = DBF::Table.new File.open('data.dbf', 'rb')
    #
    #   # working with a dbf and memo in memory
    #   table = DBF::Table.new StringIO.new(dbf_data), StringIO.new(memo_data)
    #
    #   # working with a dbf overriding specified in the dbf encoding
    #   table = DBF::Table.new 'data.dbf', nil, 'cp437'
    #   table = DBF::Table.new 'data.dbf', 'memo.dbt', Encoding::US_ASCII
    #
    # Opens a table like .new, but when given a block, yields the table,
    # closes it when the block returns, and returns the block's value —
    # the same contract as File.open.
    #
    #   DBF::Table.open('data.dbf') do |table|
    #     table.each { |record| ... }
    #   end
    #
    # Takes the same arguments as .new. Without a block, equivalent to .new.
    def self.open(data, memo = nil, encoding = nil, name: nil)
      table = new(data, memo, encoding, name: name)
      return table unless block_given?

      begin
        yield table
      ensure
        table.close
      end
    end

    # @param data [String, StringIO, IO] data Path to the dbf file or an IO-like object
    # @param memo [optional String, StringIO, IO] memo Path to the memo file or an IO-like object
    # @param encoding [optional String, Encoding] encoding Name of the encoding or an Encoding object
    def initialize(data, memo = nil, encoding = nil, name: nil)
      @data = FileHandler.open_data(data)
      @user_encoding = encoding
      @encoding = determine_encoding
      @memo = FileHandler.open_memo(data, memo, version_config.memo_class, version)
      @name = name
      yield self if block_given?
    end

    # Closes the table and memo file
    #
    # @return [TrueClass, FalseClass]
    def close
      @data.close
      @memo&.close
    end

    # @return [TrueClass, FalseClass]
    def closed?
      @data.closed? && (!@memo || @memo.closed?)
    end

    # Column names
    #
    # @return [String]
    def column_names
      @column_names ||= columns.map(&:name)
    end

    # Cumulative byte offsets for each column within a record
    #
    # @return [Array<Integer>]
    def column_offsets
      @column_offsets ||= begin
        sum = 0
        columns.map { |col| sum.tap { sum += col.length } }
      end
    end

    def record_context
      @record_context ||= RecordContext.new(columns:, version:, memo: @memo, column_offsets:)
    end

    # All columns
    #
    # @return [Array]
    def columns
      @columns ||= build_columns
    end

    # Calls block once for each record in the table. The record may be nil
    # if the record has been marked as deleted.
    #
    # @yield [nil, DBF::Record]
    def each(&)
      return enum_for(:each) unless block_given?
      return if columns.empty?

      RecordIterator.new(@data, record_context, header_length, record_length, record_count).each(&)
    end

    # @return [String]
    def filename
      File.basename(@data.path) if @data.respond_to?(:path)
    end

    # @return [TrueClass, FalseClass]
    def has_memo_file?
      !!@memo
    end

    # @return [String]
    def name
      @name ||= filename && File.basename(filename, '.*')
    end

    # Retrieve a record by index number.
    # The record will be nil if it has been deleted, but not yet pruned from
    # the database.
    #
    # @param [Integer] index
    # @return [DBF::Record, NilClass]
    def record(index)
      raise DBF::NoColumnsDefined, 'The DBF file has no columns defined' if columns.empty?

      seek_to_record(index)
      return nil if deleted_record?

      record_data = @data.read(record_length)
      # A file that ends immediately after the delete flag has no record body;
      # treat it as absent rather than building a Record over nil data.
      return nil unless record_data

      DBF::Record.new(record_data, record_context)
    end

    alias row record

    # Dumps all records to a CSV file.  If no filename is given then CSV is
    # output to STDOUT.
    #
    # @param [optional String, IO] path_or_io String path, IO-like object, or nil for STDOUT
    def to_csv(path_or_io = nil)
      if path_or_io.is_a?(String)
        File.open(path_or_io, 'w') { |file| write_csv(file) }
      else
        write_csv(path_or_io || $stdout)
      end
    end

    # Human readable version description
    #
    # @return [String]
    def version_description
      version_config.version_description
    end

    # Encode string
    #
    # @param [String] string
    # @return [String]
    def encode_string(string) # :nodoc:
      Encoder.encode(string, @encoding)
    end

    # Encoding specified in the file header
    #
    # @return [Encoding]
    def header_encoding
      header.encoding
    end

    private

    def write_csv(io) # :nodoc:
      csv = CSV.new(io, force_quotes: true)
      csv << column_names.map { |name| csv_safe_value(name) }
      each { |record| csv << record.to_a.map { |value| csv_safe_value(value) } }
    end

    # Neutralizes spreadsheet formula injection (CWE-1236) on CSV export by
    # prefixing a single quote to string cells that begin with a formula
    # trigger character. Non-string values (numbers, dates, booleans) are
    # returned unchanged. The leading byte is compared numerically so that a
    # value whose bytes are invalid in its encoding cannot raise here.
    def csv_safe_value(value) # :nodoc:
      return value unless value.is_a?(::String)

      value = csv_compatible(value)
      return value unless CSV_FORMULA_TRIGGERS.include?(value.getbyte(0))

      quote = +"'"
      quote.force_encoding(value.encoding) + value
    end

    # A row is written as a single string, so a binary (General/OLE) or
    # invalidly encoded cell would raise Encoding::CompatibilityError when
    # combined with text cells. Represent those bytes instead of raising.
    def csv_compatible(value) # :nodoc:
      return value if value.ascii_only?
      return value if value.valid_encoding? && value.encoding != Encoding::BINARY

      value.dup.force_encoding(Encoding::UTF_8).scrub('?')
    end

    def version_config
      @version_config ||= VersionConfig.new(version)
    end

    def determine_encoding
      @user_encoding || header.encoding || Encoding.default_external
    end

    def build_columns # :nodoc:
      ColumnBuilder.new(self, @data, version_config).build
    end

    def deleted_record? # :nodoc:
      flag = @data.read(1)
      flag ? flag.getbyte(0) == 0x2A : true
    end

    def header # :nodoc:
      @header ||= safe_seek do
        @data.seek(0)
        Header.new(@data.read(VersionConfig::DBASE3_HEADER_SIZE))
      end
    end

    def safe_seek # :nodoc:
      original_pos = @data.pos
      yield.tap { @data.seek(original_pos) }
    end

    def seek(offset) # :nodoc:
      @data.seek(header_length + offset)
    end

    def seek_to_record(index) # :nodoc:
      seek(index * record_length)
    end
  end
end
