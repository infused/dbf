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
      # Opens a DBF::Database::Foxpro
      # Examples:
      #   # working with a database stored on the filesystem
      #   db = DBF::Database::Foxpro.new 'path_to_db/database.dbc'
      #
      #  # Calling a table
      #  contacts = db.contacts.record(0)
      #
      # @param path [String]
      # @param max_memo_size [optional Integer] Bytes to read from each memo
      #   of the container and its tables; see DBF::Table.new
      def initialize(path, max_memo_size: nil)
        @path = path
        @max_memo_size = max_memo_size
        # Open first: Table.new turns a bad path into a DBF::Error, while
        # File.dirname raises ArgumentError for one containing a null byte.
        @db = DBF::Table.new(@path, max_memo_size:)
        @dirname = File.dirname(@path)
        @tables = extract_dbc_data
      end

      def table_names
        @tables.keys
      end

      # Returns table with given name
      #
      # @param name [String]
      # @return [DBF::Table]
      def table(name)
        Table.new(table_path(name), long_names: @tables[name], max_memo_size: @max_memo_size)
      end

      # Searches the database directory for the table's dbf file
      # and returns the absolute path. Ensures case-insensitivity
      # on any platform.
      # @param name [String]
      # @return [String]
      def table_path(name)
        name = name.to_s
        raise DBF::FileNotFoundError, "related table not found: #{name}" if name.empty? || name.include?("\x00")

        # Treat the container-supplied name as an untrusted basename so that
        # path separators and ".." cannot escape the database directory.
        # Match case-insensitively by scanning the directory rather than
        # globbing, so glob metacharacters (`{}`, `*`, `?`, `[]`) in the name
        # cannot trigger brace-expansion CPU exhaustion.
        target = "#{File.basename(name)}.dbf"
        entry = Dir.children(@dirname).find { |child| child.casecmp?(target) }
        path = entry && File.join(@dirname, entry)

        raise DBF::FileNotFoundError, "related table not found: #{name}" unless path && File.exist?(path)

        # Defense in depth: confirm the resolved file really is inside the
        # database directory before opening it.
        contained = File.realpath(path).start_with?("#{File.realpath(@dirname)}#{File::SEPARATOR}")
        raise DBF::FileNotFoundError, "related table not found: #{name}" unless contained

        path
      end

      def method_missing(method, *args) # :nodoc:
        name = method.to_s
        table_method?(name) ? table(name) : super
      end

      def respond_to_missing?(method, *)
        table_method?(method.to_s) || super
      end

      private

      # Table names come from the container file, so implicit-conversion
      # method names are never dispatched to a table (see Record).
      def table_method?(name) # :nodoc:
        !Record::RESERVED_METHODS.include?(name) && @tables.key?(name)
      end

      # This method extracts the data from the database container. This is
      # just an ordinary table with a treelike structure. Field definitions
      # are in the same order as in the linked tables but only the long name
      # is provided.
      def extract_dbc_data # :nodoc:
        build_table_data.values.to_h { |entry| entry.values_at(:name, :fields) }
      end

      def build_table_data # :nodoc:
        @db.each_with_object({}) do |record, hash|
          next unless record

          name = record.objectname
          case record.objecttype
          when 'Table' then hash[record.objectid] = table_field_hash(name)
          when 'Field' then (hash[record.parentid] ||= table_field_hash('UNKNOWN'))[:fields] << name
          end
        end
      end

      def table_field_hash(name)
        {name:, fields: []}
      end
    end

    class Table < DBF::Table
      attr_reader :long_names

      def initialize(path, long_names:, max_memo_size: nil)
        @long_names = long_names
        super(path, max_memo_size:)
      end

      # Replaces each column's short name with its long name from the
      # container. Long names were decoded when the .dbc was read, so they
      # are not decoded again with this table's code page.
      def build_columns # :nodoc:
        super.each_with_index.map do |column, index|
          long_name = long_names[index]
          long_name ? column.with_name(long_name) : column
        end
      end
    end
  end
end
