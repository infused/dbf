module DBF
  class ColumnLengthError < DBFError; end
  
  class Column
    attr_reader :name, :type, :length, :decimal
    
    def initialize(name, type, length, decimal)
      raise ColumnLengthError, "field length must be greater than 0" unless length > 0
      @name, @type, @length, @decimal = strip_non_ascii_chars(name), type, length, decimal
    end
    
    def schema_definition
      data_type = case type
      when "N" # number
        if decimal > 0
          ":float"
        else
          ":integer"
        end
      when "I" # integer
        ":integer"
      when "D" # date
        ":date"
      when "T" # datetime
        ":datetime"
      when "L" # boolean
        ":boolean"
      when "M" # memo
        ":text"
      else
        ":string, :limit => #{length}"
      end
      
      "\"#{name.underscore}\", #{data_type}\n"
    end
    
    private
    
    def strip_non_ascii_chars(s)
      clean = ''
      s.each_byte do |char|
        clean << char if char > 31 && char < 128
      end
      clean
    end
  end
  
end