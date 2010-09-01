module DBF
  class ColumnLengthError < StandardError; end
  class ColumnNameError < StandardError; end
  
  # DBF::Column stores all the information about a column including its name,
  # type, length and number of decimal places (if any)
  class Column
    attr_reader :name, :type, :length, :decimal
    
    # Initialize a new DBF::Column
    #
    # @param [String] name
    # @param [String] type
    # @param [Fixnum] length
    # @param [Fixnum] decimal
    def initialize(name, type, length, decimal)
      @name, @type, @length, @decimal = strip_non_ascii_chars(name), type, length, decimal
      
      raise ColumnLengthError, "field length must be greater than 0" unless length > 0
      raise ColumnNameError, "column name cannot be empty" if @name.length == 0
    end
    
    # Cast value to native type
    #
    # @param [String] value
    # @return [Fixnum, Float, Date, DateTime, Boolean, String] 
    def type_cast(value)
      case type
      when 'N' # number
        unpack_number(value)
      when 'I' # integer
        unpack_unsigned_long(value)
      when 'F' # float
        unpack_float(value)
      when 'D' # date
        decode_date(value)
      when 'T' # datetime
        decode_datetime(value)
      when 'L' # logical
        boolean(value)
      else
        value.to_s.strip
      end
    end
    
    # Decode a Date value
    #
    # @param [String] value
    # @return [Date]
    def decode_date(value)
      return nil if value.blank?
      value.is_a?(String) ? value.gsub(' ', '0').to_date : value.to_date
    rescue
      nil
    end
    
    # Decode a DateTime value
    #
    # @param [String] value
    # @return [DateTime]
    def decode_datetime(value)
      days, milliseconds = value.unpack('l2')
      seconds = milliseconds / 1000
      DateTime.jd(days, seconds/3600, seconds/60 % 60, seconds % 60) rescue nil
    end
    
    # Decode a number value
    #
    # @param [String] value
    # @return [Fixnum, Float]
    def unpack_number(value)
      decimal.zero? ? unpack_integer(value) : value.to_f
    end
    
    # Decode a float value
    #
    # @param [String] value
    # @return [Float]
    def unpack_float(value)
      value.to_f
    end
    
    # Decode an integer
    #
    # @param [String] value
    # @return [Fixnum]
    def unpack_integer(value)
      value.to_i
    end
    
    # Decode an unsigned long
    #
    # @param [String] value
    # @return [Fixnum]
    def unpack_unsigned_long(value)
      value.unpack('V')[0]
    end
    
    # Decode a boolean value
    #
    # @param [String] value
    # @return [Boolean]
    def boolean(value)
      value.strip =~ /^(y|t)$/i ? true : false
    end
    
    # Schema definition
    #
    # @return [String]
    def schema_definition
      "\"#{name.underscore}\", #{schema_data_type}\n"
    end
    
    # Column type for schema definition
    #
    # @return [String]
    def schema_data_type
      case type
      when "N", "F"
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
    
    # Strip all non-ascii and non-printable characters
    #
    # @param [String] s
    # @return [String]
    def strip_non_ascii_chars(s)
      # truncate the string at the first null character
      s = s[0, s.index("\x00")] if s.index("\x00")
      
      s.gsub(/[^\x20-\x7E]/,"")
    end
    
    def memo?
      type == 'M'
    end
  end
  
end
