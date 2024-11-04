# frozen_string_literal: true

module DBF
  # DBF::Database::Foxpro is the primary interface to a Visual Foxpro database
  # container (.dbc file). When using this database container, long fieldnames
  # are supported, and you can reference tables directly instead of
  # instantiating Table objects yourself.
  # Table references are created based on the filename, but it this class
  # tries to correct the table filenames because they could be wrong for
  # case sensitive filesystems, e.g. when a foxpro database is uploaded to
  # a linux server.
  module Database
    class Foxpro
      OBJECT_TYPES = {
        TABLE: 'Table',
        FIELD: 'Field'
      }.freeze

      # Opens a DBF::Database::Foxpro
      # Examples:
      #   # working with a database stored on the filesystem
      #   db = DBF::Database::Foxpro.new 'path_to_db/database.dbc'
      #
      #  # Calling a table
      #  contacts = db.contacts.record(0)
      #
      # @param path [String]
      def initialize(path)
        raise ArgumentError, 'path must be a String' unless path.is_a?(String)

        @path = path
        @dirname = File.dirname(@path)
        @db = DBF::Table.new(@path)
        @tables = extract_dbc_data
      rescue Errno::ENOENT
        raise DBF::FileNotFoundError, "Database file not found: #{@path}"
      end

      def table_names
        @tables.keys
      end

      # Returns table with given name
      #
      # @param name [String]
      # @return [DBF::Table]
      def table(name)
        Table.new table_path(name) do |table|
          table.long_names = @tables[name]
        end
      end

      # Searches the database directory for the table's dbf file
      # and returns the absolute path. Ensures case-insensitivity
      # on any platform.
      # @param name [String]
      # @return [String]
      def table_path(name)
        glob = File.join(@dirname, "#{name}.dbf")
        path = Dir.glob(glob, File::FNM_CASEFOLD).first

        raise DBF::FileNotFoundError, "related table not found: #{name}" unless path && File.exist?(path)

        path
      end

      def method_missing(method, *args) # :nodoc:
        table_names.index(method.to_s) ? table(method.to_s) : super
      end

      def respond_to_missing?(method, *)
        table_names.index(method.to_s) || super
      end

      private

      # Extracts and processes the database container structure
      # @return [Hash] Processed table data with long field names
      def extract_dbc_data
        table_data = {}
        
        @db.each do |record|
          next unless record
          process_record(record, table_data)
        end

        normalize_table_data(table_data)
      end

      # Processes a single database record based on its object type
      # @param record [DBF::Record] The record to process
      # @param table_data [Hash] The accumulator for processed data
      def process_record(record, table_data)
        case record.objecttype
        when OBJECT_TYPES[:TABLE]
          process_table(record, table_data)
        when OBJECT_TYPES[:FIELD]
          process_field(record, table_data)
        end
      end

      # Normalizes the table data into the final format
      # @param table_data [Hash] Raw table data
      # @return [Hash] Normalized table data
      def normalize_table_data(table_data)
        table_data.values.to_h { |v| [v[:name], v[:fields]] }
      end

      def process_table(record, data)
        id = record.objectid
        name = record.objectname
        data[id] = table_field_hash(name)
      end

      def process_field(record, data)
        id = record.parentid
        name = 'UNKNOWN'
        field = record.objectname
        data[id] ||= table_field_hash(name)
        data[id][:fields] << field
      end

      def table_field_hash(name)
        {name: name, fields: []}
      end
    end

    class Table < DBF::Table
      attr_accessor :long_names

      def build_columns # :nodoc:
        columns = super

        # modify the column definitions to use the long names as the
        # columnname property is readonly, recreate the column definitions
        columns.map do |column|
          long_name = long_names[columns.index(column)]
          Column.new(self, long_name, column.type, column.length, column.decimal)
        end
      end
    end
  end
end
