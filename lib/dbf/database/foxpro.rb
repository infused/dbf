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

          extract_dbc_data
        rescue Errno::ENOENT
          raise DBF::FileNotFoundError.new("file not found: #{data}")
        end
      end

      def tables
        @tables.keys
      end

      # returns table with given name (Foxtable)
      def table(name)
        table = Table.new(table_path name)
        table.longnames = @tables[name]
        table
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

      def method_missing(method, *args)
        if index = tables.index(method.to_s)
          table method.to_s
        else
          super
        end
      end


      private

      # This method extracts the data from the database container. This is just an ordinary table
      # with a treelike structure. Field definitions are in the same order as in the linked tables
      # but only the long name is provided.
      def extract_dbc_data
        tabledata = {}

        curt = nil
        @db.each do |r|
          unless r.nil?
            if r.objecttype == "Table"
              # This is a related table
              tabledata[r.objectid] = {:name => r.objectname, :fields => []}
            elsif r.objecttype == "Field"
              # This is a related field. The parentid points to the table object

              # create using the parentid if the parentid is still unknown.
              tabledata[r.parentid] = {:name => "UNKNOWN", :fields => []} unless tabledata.has_key?(r.parentid)
              tabledata[r.parentid][:fields] << r.objectname
            end
          end
        end

        # now we need to transform the resulting array-hash to a direct mapping (changed to support older Ruby versions)
        # { tablename => [fieldnames] }
        @tables = {}
        tabledata.each{|k, v| @tables[v[:name]] = v[:fields] }
      end

    end

    class Table < DBF::Table
      attr_accessor :longnames

      def build_columns
        columns = super
        # modify the column definitions to use the long names
        # as the columnname property is readonly, recreate the column definitions
        idx = 0
        columns.map do |item|
          idx += 1
          column_class.new(self, longnames[idx-1], item.type, item.length, item.decimal)
        end

      end
    end
  end

end
