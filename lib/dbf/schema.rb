module DBF
  # The Schema module is mixin for the Table class
  module Schema
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
    # @param [Symbol] format Valid options are :activerecord and :json
    # @return [String]
    def schema(format = :activerecord, table_only = false)
      supported_formats = [:activerecord, :json, :sequel]
      if supported_formats.include?(format)
        send("#{format}_schema", table_only)
      else
        raise ArgumentError
      end
    end

    def activerecord_schema(_table_only = false)
      s = "ActiveRecord::Schema.define do\n"
      s << "  create_table \"#{name}\" do |t|\n"
      columns.each do |column|
        s << "    t.column #{column.schema_definition}"
      end
      s << "  end\nend"
      s
    end

    def sequel_schema(table_only = false)
      s = ''
      s << "Sequel.migration do\n" unless table_only
      s << "  change do\n " unless table_only
      s << "    create_table(:#{name}) do\n"
      columns.each do |column|
        s << "      column #{column.sequel_schema_definition}"
      end
      s << "    end\n"
      s << "  end\n"  unless table_only
      s << "end\n"  unless table_only
      s
    end

    def json_schema(_table_only = false)
      columns.map(&:to_hash).to_json
    end
  end
end
