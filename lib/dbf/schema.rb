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
    # @return [String]
    def schema(format = :activerecord)
      supported_formats = [:activerecord]
      if supported_formats.include?(format)
        send "#{format}_schema"
      else
        raise ArgumentError
      end
    end

    def activerecord_schema
      s = "ActiveRecord::Schema.define do\n"
      s << "  create_table \"#{File.basename(@data.path, ".*")}\" do |t|\n"
      columns.each do |column|
        s << "    t.column #{column.schema_definition}"
      end
      s << "  end\nend"
      s
    end
  end
end
