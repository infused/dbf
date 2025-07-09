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

    DBASE2_HEADER_SIZE = 8
    DBASE3_HEADER_SIZE = 32
    DBASE7_HEADER_SIZE = 68

    VERSIONS = {
      '02' => 'FoxBase',
      '03' => 'dBase III without memo file',
      '04' => 'dBase IV without memo file',
      '05' => 'dBase V without memo file',
      '07' => 'Visual Objects 1.x',
      '30' => 'Visual FoxPro',
      '32' => 'Visual FoxPro with field type Varchar or Varbinary',
      '31' => 'Visual FoxPro with AutoIncrement field',
      '43' => 'dBASE IV SQL table files, no memo',
      '63' => 'dBASE IV SQL system files, no memo',
      '7b' => 'dBase IV with memo file',
      '83' => 'dBase III with memo file',
      '87' => 'Visual Objects 1.x with memo file',
      '8b' => 'dBase IV with memo file',
      '8c' => 'dBase 7',
      '8e' => 'dBase IV with SQL table',
      'cb' => 'dBASE IV SQL table files, with memo',
      'f5' => 'FoxPro with memo file',
      'fb' => 'FoxPro without memo file'
    }.freeze

    FOXPRO_VERSIONS = {
      '30' => 'Visual FoxPro',
      '31' => 'Visual FoxPro with AutoIncrement field',
      'f5' => 'FoxPro with memo file',
      'fb' => 'FoxPro without memo file'
    }.freeze

    attr_accessor :encoding
    attr_writer :name

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
    def initialize(data, memo = nil, encoding = nil)
      @data = open_data(data)
      @encoding = encoding || header.encoding || Encoding.default_external
      @memo = open_memo(data, memo)
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
      if @memo
        @data.closed? && @memo.closed?
      else
        @data.closed?
      end
    end

    # Column names
    #
    # @return [String]
    def column_names
      @column_names ||= columns.map(&:name)
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
    def each
      record_count.times { |i| yield record(i) }
    end

    # @return [String]
    def filename
      return unless @data.respond_to?(:path)

      File.basename(@data.path)
    end

    # Find records using a simple ActiveRecord-like syntax.
    #
    # Examples:
    #   table = DBF::Table.new 'mydata.dbf'
    #
    #   # Find record number 5
    #   table.find(5)
    #
    #   # Find all records for Keith Morrison
    #   table.find :all, first_name: "Keith", last_name: "Morrison"
    #
    #   # Find first record
    #   table.find :first, first_name: "Keith"
    #
    # The <b>command</b> may be a record index, :all, or :first.
    # <b>options</b> is optional and, if specified, should be a hash where the
    # keys correspond to column names in the database.  The values will be
    # matched exactly with the value in the database.  If you specify more
    # than one key, all values must match in order for the record to be
    # returned.  The equivalent SQL would be "WHERE key1 = 'value1'
    # AND key2 = 'value2'".
    #
    # @param command [Integer, Symbol] command
    # @param options [optional, Hash] options Hash of search parameters
    # @yield [optional, DBF::Record, NilClass]
    def find(command, options = {}, &block)
      case command
      when Integer
        record(command)
      when Array
        command.map { |i| record(i) }
      when :all
        find_all(options, &block)
      when :first
        find_first(options)
      end
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
      DBF::Record.new(record_data, columns, version, @memo)
    end

    alias row record

    # Dumps all records to a CSV file.  If no filename is given then CSV is
    # output to STDOUT.
    #
    # @param [optional String] path Defaults to STDOUT
    def to_csv(path = nil)
      out_io = path ? File.open(path, 'w') : $stdout
      csv = CSV.new(out_io, force_quotes: true)
      csv << column_names
      each { |record| csv << record.to_a }
    end

    # Human readable version description
    #
    # @return [String]
    def version_description
      VERSIONS[version]
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

    def build_columns # :nodoc:
      safe_seek do
        @data.seek(header_size)
        [].tap do |columns|
          until end_of_record?
            args = case version
            when '02'
              [self, *@data.read(header_size * 2).unpack('A11 a C'), 0]
            when '04', '8c'
              [self, *@data.read(48).unpack('A32 a C C x13')]
            else
              [self, *@data.read(header_size).unpack('A11 a x4 C2')]
            end

            columns << Column.new(*args)
          end
        end
      end
    end

    def header_size
      case version
      when '02'
        DBASE2_HEADER_SIZE
      when '04', '8c'
        DBASE7_HEADER_SIZE
      else 
        DBASE3_HEADER_SIZE
      end
    end

    def deleted_record? # :nodoc:
      flag = @data.read(1)
      flag ? flag.unpack1('a') == '*' : true
    end

    def end_of_record? # :nodoc:
      safe_seek { @data.read(1).ord == 13 }
    end

    def find_all(options) # :nodoc:
      select do |record|
        next unless record&.match?(options)

        yield record if block_given?
        record
      end
    end

    def find_first(options) # :nodoc:
      detect { |record| record&.match?(options) }
    end

    def foxpro? # :nodoc:
      FOXPRO_VERSIONS.key?(version)
    end

    def header # :nodoc:
      @header ||= safe_seek do
        @data.seek(0)
        Header.new(@data.read(DBASE3_HEADER_SIZE))
      end
    end

    def memo_class # :nodoc:
      @memo_class ||= if foxpro?
        Memo::Foxpro
      else
        version == '83' ? Memo::Dbase3 : Memo::Dbase4
      end
    end

    def memo_search_path(io) # :nodoc:
      dirname = File.dirname(io)
      basename = File.basename(io, '.*')
      "#{dirname}/#{basename}*.{fpt,FPT,dbt,DBT}"
    end

    def open_data(data) # :nodoc:
      case data
      when StringIO
        data
      when String
        File.open(data, 'rb')
      else
        raise ArgumentError, 'data must be a file path or StringIO object'
      end
    rescue Errno::ENOENT
      raise DBF::FileNotFoundError, "file not found: #{data}"
    end

    def open_memo(data, memo = nil) # :nodoc:
      if memo
        meth = memo.is_a?(StringIO) ? :new : :open
        memo_class.send(meth, memo, version)
      elsif !data.is_a?(StringIO)
        files = Dir.glob(memo_search_path(data))
        files.any? ? memo_class.open(files.first, version) : nil
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
