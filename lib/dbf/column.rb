module DBF
  class ColumnLengthError < DBFError; end
  
  class Column
    attr_reader :name, :type, :length, :decimal
    
    def initialize(name, type, length, decimal)
      raise ColumnLengthError, "field length must be greater than 0" unless length > 0
      @name, @type, @length, @decimal = strip_non_ascii_chars(name), type, length, decimal
    end
    
    def type_cast(value)
      case column.type
      when 'N' # number
        column.decimal.zero? ? value.to_i : value.to_f
      when 'D' # date
        raw.to_time unless raw.blank?
      when 'M' # memo
        starting_block = value.to_i
        # read_memo(starting_block)
      when 'L' # logical
        value.strip =~ /^(y|t)$/i ? true : false
      when 'I' # integer
        value.unpack('v').first
      when 'T' # datetime
        unpack_datetime(value)
      else
        value.to_s.strip
      end
    end
    
    def unpack_datetime(value)
      days, milliseconds = value.unpack('l2')
      hours = (milliseconds / MS_PER_HOUR).to_i
      minutes = ((milliseconds - (hours * MS_PER_HOUR)) / MS_PER_MINUTE).to_i
      seconds = ((milliseconds - (hours * MS_PER_HOUR) - (minutes * MS_PER_MINUTE)) / MS_PER_SECOND).to_i
      DateTime.jd(days, hours, minutes, seconds)
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