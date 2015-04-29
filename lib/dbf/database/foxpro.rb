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

      def initialize(path_to_dbc)
        begin
          @dbcname = path_to_dbc
          @basedir = File.dirname(@dbcname)
          @db = DBF::Table.new(@dbcname)

          extract_dbc_data
        rescue Errno::ENOENT => error
          raise DBF::FileNotFoundError.new("file not found: #{data}")
        end
      end


      def tables
        @tables.keys
      end

      # returns table with given name (Foxtable)
      def table name
        ft = Foxtable.new(table_file_name name)
        ft.longnames = @tables[name]

        ft
      end

      # returns the filename of the related table. Checks if it exists, and tries to correct the filename for case sensitive filesystems.
      def table_file_name name
        suggested_filename = File.join(@basedir, "#{name}.dbf")
        unless File.exist?(suggested_filename)
          # if this file does not exist (because of casing), try to find it. It comes from a case insensitive filesystem
          # so no doubles can exists.
          suggested_filename = suggested_filename.downcase
          suggested_filename = Dir.glob('*').find { |f| f.downcase == suggested_filename }

          raise DBF::FileNotFoundError.new("related table not found: #{name}") if suggested_filename.nil?
          raise DBF::FileNotFoundError.new("related table not found: #{name}") unless File.exist?(suggested_filename)
        end

        suggested_filename
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

    class Foxtable < DBF::Table
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
