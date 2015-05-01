module DBF
  # DBF::Database::Foxpro is the primary interface to a Visual Foxpro database container (.dbc file).
  # When using this database container, long fieldnames are supported, and you can reference tables
  # directly instead of instantiating Table objects yourself.
  # Table references are created based on the filename, but it this class tries to correct the
  # table filenames because they could be wrong for case sensitive filesystems, e.g. when
  # a foxpro database is uploaded to a linux server.
  module Database

    class Foxpro
      # Opens a DBF::Database::Foxpro
      # Examples:
      #   # working with a database stored on the filesystem
      #   db = DBF::Database::Foxpro.new 'path_to_db/database.dbc'
      #
      #  # Calling a table
      #  contacts = db.contacts.record(0)
      def initialize(path)
        begin
          @path = path
          @dirname = File.dirname(@path)
          @db = DBF::Table.new(@path)
          @tables = extract_dbc_data

        rescue Errno::ENOENT
          raise DBF::FileNotFoundError.new("file not found: #{data}")
        end
      end

      def table_names
        @tables.keys
      end

      # Returns table with given name
      # @return Table
      def table(name)
        Table.new(table_path name) do |table|
          table.long_names = @tables[name]
        end
      end

      # Searches the database directory for the table's dbf file
      # and returns the absolute path. Ensures case-insensitivity
      # on any platform.
      # @return String
      def table_path(name)
        example = File.join(@dirname, "#{name}.dbf")
        glob = File.join(@dirname, '*')
        path = Dir.glob(glob).find { |match| match.downcase == example.downcase }

        unless path && File.exist?(path)
          raise DBF::FileNotFoundError.new("related table not found: #{name}")
        end

        path
      end

      def method_missing(method, *args) # nodoc
        if index = table_names.index(method.to_s)
          table method.to_s
        else
          super
        end
      end

      private

      # This method extracts the data from the database container. This is just an ordinary table
      # with a treelike structure. Field definitions are in the same order as in the linked tables
      # but only the long name is provided.
      def extract_dbc_data # nodoc
        data = {}

        @db.each do |record|
          next unless record

          case record.objecttype
          when 'Table'
            # This is a related table
            data[record.objectid] = {:name => record.objectname, :fields => []}
          when 'Field'
            # This is a related field. The parentid points to the table object.
            # Create using the parentid if the parentid is still unknown.
            data[record.parentid] ||= {:name => "UNKNOWN", :fields => []}
            data[record.parentid][:fields] << record.objectname
          end
        end

        tables = {}
        data.each { |k, v| tables[v[:name]] = v[:fields] }
        tables
      end

    end

    class Table < DBF::Table
      attr_accessor :long_names

      def build_columns # nodoc
        columns = super

        # modify the column definitions to use the long names as the
        # columnname property is readonly, recreate the column definitions
        columns.map.with_index do |column, index|
          column_class.new(self, long_names[index], column.type, column.length, column.decimal)
        end

      end
    end
  end
end
