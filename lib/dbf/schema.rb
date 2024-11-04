module DBF
  # The Schema module provides schema generation capabilities for DBF tables
  module Schema
    FORMATS = [:activerecord, :json, :sequel].freeze

    # Maps DBF data types to their corresponding schema data types
    SCHEMA_DATA_TYPES = {
      'Y' => ':decimal, :precision => 15, :scale => 4',
      'D' => ':date',
      'T' => ':datetime', 
      'L' => ':boolean',
      'M' => ':text',
      'B' => ':binary'
    }.freeze

    # Generate a database schema in the specified format
    #
    # DBF data types are mapped to generic types as follows:
    # - Numbers without decimals -> :integer
    # - Numbers with decimals -> :float
    # - Dates -> :datetime
    # - Logical -> :boolean
    # - Memo -> :text
    # - Character -> :string with :limit
    #
    # Example ActiveRecord schema:
    #   create_table "mydata" do |t|
    #     t.column :name, :string, :limit => 30
    #     t.column :last_update, :datetime
    #     t.column :is_active, :boolean
    #     t.column :age, :integer
    #     t.column :notes, :text
    #   end
    #
    # @param format [Symbol] Schema format (:activerecord, :json, or :sequel)
    # @param table_only [Boolean] Whether to output just the table definition
    # @return [String] Generated schema
    def schema(format = :activerecord, table_only: false)
      schema_method = schema_name(format)
      send(schema_method, table_only: table_only)
    rescue NameError
      raise ArgumentError, "Invalid schema format :#{format}. Valid formats are: #{FORMATS.join(', ')}."
    end

    def schema_name(format)
      "#{format}_schema"
    end

    def activerecord_schema(table_only: false)
      schema = "ActiveRecord::Schema.define do\n"
      schema << "  create_table \"#{name}\" do |t|\n"
      columns.each do |column|
        schema << "    t.column #{activerecord_schema_definition(column)}"
      end
      schema << "  end\nend"
      schema
    end

    def sequel_schema(table_only: false)
      schema = ''
      schema << "Sequel.migration do\n" unless table_only
      schema << "  change do\n " unless table_only
      schema << "    create_table(:#{name}) do\n"
      columns.each do |column|
        schema << "      column #{sequel_schema_definition(column)}"
      end
      schema << "    end\n"
      schema << "  end\n" unless table_only
      schema << "end\n" unless table_only
      schema
    end

    def json_schema(table_only: false)
      columns.map(&:to_hash).to_json
    end

    def activerecord_schema_definition(column)
      "\"#{column.underscored_name}\", #{schema_data_type(column, :activerecord)}\n"
    end

    def sequel_schema_definition(column)
      ":#{column.underscored_name}, #{schema_data_type(column, :sequel)}\n"
    end

    def schema_data_type(column, format = :activerecord)
      case column.type
      when 'N', 'F', 'I'
        number_data_type(column)
      when 'Y', 'D', 'T', 'L', 'M', 'B'
        SCHEMA_DATA_TYPES[column.type]
      else
        string_data_format(format, column)
      end
    end

    def number_data_type(column)
      column.decimal.positive? ? ':float' : ':integer'
    end

    def string_data_format(format, column)
      size_option = format == :sequel ? 'size' : 'limit'
      ":#{format == :sequel ? 'varchar' : 'string'}, :#{size_option} => #{column.length}"
    end
  end
end
