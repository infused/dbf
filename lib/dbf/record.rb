module DBF
  class Record
    attr_reader :attributes
    
    @@accessors_defined = false
    
    def initialize(table)
      @table, @data, @memo = table, table.data, table.memo
      @attributes = {}
      initialize_values(table.columns)
      define_accessors
      self
    end
    
    private
    
    def define_accessors
      return if @@accessors_defined
      @table.columns.each do |column|
        underscored_column_name = underscore(column.name)
        if @table.options[:accessors] && !respond_to?(underscored_column_name)
          self.class.send :define_method, underscored_column_name do
            @attributes[column.name]
          end
          @@accessors_defined = true
        end
      end
    end
    
    def initialize_values(columns)
      columns.each do |column|
        case column.type
        when 'N' # number
          @attributes[column.name] = column.decimal.zero? ? unpack_string(column).to_i : unpack_string(column).to_f
        when 'D' # date
          raw = unpack_string(column).strip
          unless raw.empty?
            begin
              parts = raw.match(DATE_REGEXP).to_a.slice(1,3).map {|n| n.to_i}
              @attributes[column.name] = Time.gm(*parts)
            rescue
              parts = raw.match(DATE_REGEXP).to_a.slice(1,3).map {|n| n.to_i}
              @attributes[column.name] = Date.new(*parts)
            end
          end
        when 'M' # memo
          starting_block = unpack_string(column).to_i
          @attributes[column.name] = read_memo(starting_block)
        when 'L' # logical
          @attributes[column.name] = unpack_string(column) =~ /^(y|t)$/i ? true : false
        when 'I' # integer
          @attributes[column.name] = unpack_integer(column)
        when 'T' # datetime
          @attributes[column.name] = unpack_datetime(column)
        else
          @attributes[column.name] = unpack_string(column).strip
        end
      end
    end
  
    def unpack_column(column)
      @data.read(column.length).unpack("a#{column.length}")
    end
  
    def unpack_string(column)
      unpack_column(column).to_s
    end
    
    def unpack_integer(column)
      @data.read(column.length).unpack("v").first
    end
    
    def unpack_datetime(column)
      days, milliseconds = @data.read(column.length).unpack('l2')
      hours = (milliseconds / MS_PER_HOUR).to_i
      minutes = ((milliseconds - (hours * MS_PER_HOUR)) / MS_PER_MINUTE).to_i
      seconds = ((milliseconds - (hours * MS_PER_HOUR) - (minutes * MS_PER_MINUTE)) / MS_PER_SECOND).to_i
      DateTime.jd(days, hours, minutes, seconds)
    end
  
    def read_memo(start_block)
      return nil if start_block <= 0 || @table.memo_block_size.nil?
      @memo.seek(start_block * @table.memo_block_size)
      if @table.memo_file_format == :fpt
        memo_type, memo_size, memo_string = @memo.read(@table.memo_block_size).unpack("NNa56")
      
        # skip the memo if it isn't text
        return nil unless memo_type == 1
        
        memo_block_content_size = @table.memo_block_size - FPT_BLOCK_HEADER_SIZE
        if memo_size > memo_block_content_size
          memo_string << @memo.read(memo_size - @table.memo_block_size + FPT_BLOCK_HEADER_SIZE)
        elsif memo_size > 0 and memo_size < memo_block_content_size
          memo_string = memo_string[0, memo_size]
        end
      else
        case @table.version
        when "83" # dbase iii
          memo_string = ""
          loop do
            memo_string << block = @memo.read(512)
            break if block.strip.size < 512
          end
        when "8b" # dbase iv
          memo_type, memo_size = @memo.read(8).unpack("LL")
          memo_string = @memo.read(memo_size)
        end
      end
      memo_string
    end
    
    def underscore(camel_cased_word)
      camel_cased_word.to_s.gsub(/::/, '/').
        gsub(/([A-Z]+)([A-Z][a-z])/,'\1_\2').
        gsub(/([a-z\d])([A-Z])/,'\1_\2').
        tr("-", "_").
        downcase
    end
  end
end