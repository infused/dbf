module DBF
  class FileNotFoundError < StandardError
  end

  # DBF::Table is the primary interface to a single DBF file and provides
  # methods for enumerating and searching the records.
  class Table
    include Enumerable

    DBF_HEADER_SIZE = 32

    VERSIONS = {
      "02" => "FoxBase",
      "03" => "dBase III without memo file",
      "04" => "dBase IV without memo file",
      "05" => "dBase V without memo file",
      "07" => "Visual Objects 1.x",
      "30" => "Visual FoxPro",
      "31" => "Visual FoxPro with AutoIncrement field",
      "43" => "dBASE IV SQL table files, no memo",
      "63" => "dBASE IV SQL system files, no memo",
      "7b" => "dBase IV with memo file",
      "83" => "dBase III with memo file",
      "87" => "Visual Objects 1.x with memo file",
      "8b" => "dBase IV with memo file",
      "8e" => "dBase IV with SQL table",
      "cb" => "dBASE IV SQL table files, with memo",
      "f5" => "FoxPro with memo file",
      "fb" => "FoxPro without memo file"
    }

    FOXPRO_VERSIONS = {
      "30" => "Visual FoxPro",
      "31" => "Visual FoxPro with AutoIncrement field",
      "f5" => "FoxPro with memo file",
      "fb" => "FoxPro without memo file"
    }

    attr_reader   :header
    attr_accessor :encoding             # Source encoding (for ex. :cp1251)

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
    # @param [String, StringIO] data Path to the dbf file or a StringIO object
    # @param [optional String, StringIO] memo Path to the memo file or a StringIO object
    # @param [optional String, Encoding] encoding Name of the encoding or an Encoding object
    def initialize(data, memo = nil, encoding = nil)
      begin
        @data = open_data(data)
        @data.rewind
        @header = Header.new(@data.read(DBF_HEADER_SIZE), supports_encoding?)
        @encoding = encoding || header.encoding
        @memo = open_memo(data, memo)
      rescue StandardError => error
        raise DBF::FileNotFoundError.new('file not found: ')
      end
    end

    # @return [TrueClass, FalseClass]
    def has_memo_file?
      !!@memo
    end

    # Closes the table and memo file
    #
    # @return [TrueClass, FalseClass]
    def close
      @data.close
      @memo && @memo.close
    end

    # @return [TrueClass, FalseClass]
    def closed?
      if @memo
        @data.closed? && @memo.closed?
      else
        @data.closed?
      end
    end

    # @return String
    def filename
      File.basename @data.path
    end

    # Calls block once for each record in the table. The record may be nil
    # if the record has been marked as deleted.
    #
    # @yield [nil, DBF::Record]
    def each
      header.record_count.times {|i| yield record(i)}
    end

    # Retrieve a record by index number.
    # The record will be nil if it has been deleted, but not yet pruned from
    # the database.
    #
    # @param [Fixnum] index
    # @return [DBF::Record, NilClass]
    def record(index)
      seek_to_record(index)
      if !deleted_record?
        DBF::Record.new(@data.read(header.record_length), columns, version, @memo)
      end
    end

    alias_method :row, :record

    # Internal dBase version number
    #
    # @return [String]
    def version
      @version ||= header.version
    end

    # Total number of records
    #
    # @return [Fixnum]
    def record_count
      @record_count ||= header.record_count
    end

    # Human readable version description
    #
    # @return [String]
    def version_description
      VERSIONS[version]
    end

    # Generate an ActiveRecord::Schema
    #
    # xBase data types are converted to generic types as follows:
    # - Number columns with no decimals are converted to :integer
    # - Number columns with decimals are converted to :float
    # - Date columns are converted to :datetime
    # - Logical columns are converted to :boolean
    # - Memo columns are converted to :text
    # - Character columns are converted to :string and the :limit option is set
    #   to the length of the character column
    #
    # Example:
    #   create_table "mydata" do |t|
    #     t.column :name, :string, :limit => 30
    #     t.column :last_update, :datetime
    #     t.column :is_active, :boolean
    #     t.column :age, :integer
    #     t.column :notes, :text
    #   end
    #
    # @return [String]
    def schema
      s = "ActiveRecord::Schema.define do\n"
      s << "  create_table \"#{File.basename(@data.path, ".*")}\" do |t|\n"
      columns.each do |column|
        s << "    t.column #{column.schema_definition}"
      end
      s << "  end\nend"
      s
    end

    # Dumps all records to a CSV file.  If no filename is given then CSV is
    # output to STDOUT.
    #
    # @param [optional String] path Defaults to STDOUT
    def to_csv(path = nil)
      csv = csv_class.new((path ? File.open(path, 'w') : $stdout), :force_quotes => true)
      csv << columns.map {|c| c.name}
      each {|record| csv << record.to_a}
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
    #   table.find :all, :first_name => "Keith", :last_name => "Morrison"
    #
    #   # Find first record
    #   table.find :first, :first_name => "Keith"
    #
    # The <b>command</b> may be a record index, :all, or :first.
    # <b>options</b> is optional and, if specified, should be a hash where the keys correspond
    # to column names in the database.  The values will be matched exactly with the value
    # in the database.  If you specify more than one key, all values must match in order
    # for the record to be returned.  The equivalent SQL would be "WHERE key1 = 'value1'
    # AND key2 = 'value2'".
    #
    # @param [Fixnum, Symbol] command
    # @param [optional, Hash] options Hash of search parameters
    # @yield [optional, DBF::Record, NilClass]
    def find(command, options = {}, &block)
      case command
      when Fixnum
        record(command)
      when Array
        command.map {|i| record(i)}
      when :all
        find_all(options, &block)
      when :first
        find_first(options)
      end
    end

    # All columns
    #
    # @return [DBF::Column::Dbase, DBF::Column::Foxpro]
    def columns
      @columns ||= build_columns
    end

    # Column names
    #
    # @return [String]
    def column_names
      columns.map { |column| column.name }
    end

    # Is string encoding supported?
    # String encoding is always supported in Ruby 1.9+.
    # Ruby 1.8.x requires that Ruby be compiled with iconv support.
    def supports_encoding?
      supports_string_encoding? || supports_iconv?
    end

    # Does String support encoding?  Should be true in Ruby 1.9+
    def supports_string_encoding?
      ''.respond_to?(:encoding)
    end

    def supports_iconv? #nodoc
      require 'iconv'
      true
    rescue
      false
    end

    private

    def build_columns #nodoc
      columns = []
      @data.seek(DBF_HEADER_SIZE)
      while !["\0", "\r"].include?(first_byte = @data.read(1))
        column_data = first_byte + @data.read(DBF_HEADER_SIZE - 1)
        name, type, length, decimal = column_data.unpack('a10 x a x4 C2')
        if length > 0
          columns << column_class.new(self, name, type, length, decimal)
        end
      end
      columns
    end


    def foxpro? #nodoc
      FOXPRO_VERSIONS.keys.include? version
    end

    def column_class #nodoc
      @column_class ||= foxpro? ? Column::Foxpro : Column::Dbase
    end

    def memo_class #nodoc
      @memo_class ||= if foxpro?
        Memo::Foxpro
      else
        if version == "83"
          Memo::Dbase3
        else
          Memo::Dbase4
        end
      end
    end

    def column_count #nodoc
      @column_count ||= ((header.header_length - DBF_HEADER_SIZE + 1) / DBF_HEADER_SIZE).to_i
    end

    def open_data(data) #nodoc
      data.is_a?(StringIO) ? data : File.open(data, 'rb')
    end

    def open_memo(data, memo = nil) #nodoc
      if memo.is_a? StringIO
        memo_class.new(memo, version)
      elsif memo
        memo_class.open(memo, version)
      elsif !data.is_a? StringIO
        files = Dir.glob(memo_search_path(data))
        files.any? ? memo_class.open(files.first, version) : nil
      else
        nil
      end
    end

    def memo_search_path(io) #nodoc
      dirname = File.dirname(io)
      basename = File.basename(io, '.*')
      "#{dirname}/#{basename}*.{fpt,FPT,dbt,DBT}"
    end

    def find_all(options) #nodoc
      map do |record|
        if record && record.match?(options)
          yield record if block_given?
          record
        end
      end.compact
    end

    def find_first(options) #nodoc
      detect {|record| record && record.match?(options)}
    end

    def deleted_record? #nodoc
      @data.read(1).unpack('a') == ['*']
    end

    def seek(offset) #nodoc
      @data.seek header.header_length + offset
    end

    def seek_to_record(index) #nodoc
      seek(index * header.record_length)
    end

    def csv_class #nodoc
      @csv_class ||= CSV.const_defined?(:Reader) ? FCSV : CSV
    end
  end

end
