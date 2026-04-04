# frozen_string_literal: true

module DBF
  class FileNotFoundError < StandardError
  end

  class NoColumnsDefined < StandardError
  end

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
    #   # working with a dbf and memo in memory
    #   table = DBF::Table.new StringIO.new(dbf_data), StringIO.new(memo_data)
    #
    #   # working with a dbf overriding specified in the dbf encoding
    #   table = DBF::Table.new 'data.dbf', nil, 'cp437'
    #   table = DBF::Table.new 'data.dbf', 'memo.dbt', Encoding::US_ASCII
    #
    # @param data [String, StringIO] data Path to the dbf file or a StringIO object
    # @param memo [optional String, StringIO] memo Path to the memo file or a StringIO object
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
      @record_context ||= RecordContext.new(columns: columns, version: version, memo: @memo, column_offsets: column_offsets)
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
      File.basename(@data.path) if @data.is_a?(File)
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
      DBF::Record.new(record_data, record_context)
    end

    alias row record

    # Dumps all records to a CSV file.  If no filename is given then CSV is
    # output to STDOUT.
    #
    # @param [optional String] path Defaults to STDOUT
    def to_csv(path = nil)
      csv = CSV.new(path ? File.open(path, 'w') : $stdout, force_quotes: true)
      csv << column_names
      each { |record| csv << record.to_a }
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
      string.force_encoding(@encoding).encode(Encoding.default_external, undef: :replace, invalid: :replace)
    end

    # Encoding specified in the file header
    #
    # @return [Encoding]
    def header_encoding
      header.encoding
    end

    private

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
