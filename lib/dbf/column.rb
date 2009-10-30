module DBF
  class ColumnLengthError < DBFError; end
  class ColumnNameError < DBFError; end
  
  class Column
    attr_reader :name, :type, :length, :decimal
    
    def initialize(name, type, length, decimal)
      @name, @type, @length, @decimal = strip_non_ascii_chars(name), type, length, decimal
      
      raise ColumnLengthError, "field length must be greater than 0" unless length > 0
      raise ColumnNameError, "column name cannot be empty" if @name.length == 0
    end
    
    def type_cast(value)
      case type
      when 'N' # number
        unpack_number(value)
      when 'D' # date
        value.to_date unless value.blank?
      when 'L' # logical
        boolean(value)
      when 'I' # integer
        unpack_integer(value)
      when 'T' # datetime
        decode_datetime(value)
      else
        value.to_s.strip
      end
    end
    
    def decode_datetime(value)
      days, milliseconds = value.unpack('l2')
      seconds = milliseconds / 1000
      DateTime.jd(days, seconds/3600, seconds/60 % 60, seconds % 60)
    end
    
    def unpack_number(value)
      decimal.zero? ? unpack_integer(value) : value.to_f
    end
    
    def unpack_integer(value)
      value.to_i
    end
    
    def boolean(value)
      value.strip =~ /^(y|t)$/i ? true : false
    end
    
    def schema_definition
      "\"#{name.underscore}\", #{schema_data_type}\n"
    end
    
    def schema_data_type
      case type
      when "N"
        decimal > 0 ? ":float" : ":integer"
      when "I"
        ":integer"
      when "D"
        ":date"
      when "T"
        ":datetime"
      when "L"
        ":boolean"
      when "M"
        ":text"
      else
        ":string, :limit => #{length}"
      end
    end
    
    # strip all non-ascii and non-printable characters
    def strip_non_ascii_chars(s)
      # truncate the string at the first null character
      s = s[0, s.index("\x00")] if s.index("\x00")
      
      s.gsub(/[^\x20-\x7E]/,"")
    end
  end
  
end
