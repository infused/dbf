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

    def activerecord_schema(_table_only = false) # :nodoc:
      s = "ActiveRecord::Schema.define do\n"
      s << "  create_table \"#{name}\" do |t|\n"
      columns.each do |column|
        s << "    t.column #{activerecord_schema_definition(column)}"
      end
      s << "  end\nend"
      s
    end

    def sequel_schema(table_only = false) # :nodoc:
      s = ''
      s << "Sequel.migration do\n" unless table_only
      s << "  change do\n " unless table_only
      s << "    create_table(:#{name}) do\n"
      columns.each do |column|
        s << "      column #{sequel_schema_definition(column)}"
      end
      s << "    end\n"
      s << "  end\n"  unless table_only
      s << "end\n"  unless table_only
      s
    end

    def json_schema(_table_only = false) # :nodoc:
      columns.map(&:to_hash).to_json
    end

    # ActiveRecord schema definition
    #
    # @param [DBF::Column]
    # @return [String]
    def activerecord_schema_definition(column)
      "\"#{column.underscored_name}\", #{schema_data_type(column, :activerecord)}\n"
    end

    # Sequel schema definition
    #
    # @params [DBF::Column]
    # @return [String]
    def sequel_schema_definition(column)
      ":#{column.underscored_name}, #{schema_data_type(column, :sequel)}\n"
    end

    def schema_data_type(column, format = :activerecord) # :nodoc:
      case column.type
      when 'N', 'F'
        column.decimal > 0 ? ':float' : ':integer'
      when 'I'
        ':integer'
      when 'Y'
        ':decimal, :precision => 15, :scale => 4'
      when 'D'
        ':date'
      when 'T'
        ':datetime'
      when 'L'
        ':boolean'
      when 'M'
        ':text'
      when 'B'
        ':binary'
      else
        if format == :sequel
          ":varchar, :size => #{column.length}"
        else
          ":string, :limit => #{column.length}"
        end
      end
    end
  end
end
