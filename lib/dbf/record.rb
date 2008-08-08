module DBF
  class Record
    include Helpers
    
    attr_reader :attributes
    
    def initialize(table)
      @table, @data, @memo = table, table.data, table.memo
      initialize_values(table.columns)
      define_accessors
    end
    
    def ==(other)
      other.respond_to?(:attributes) && other.attributes == attributes
    end
    
    private
    
    def define_accessors
      @table.columns.each do |column|
        underscored_column_name = underscore(column.name)
        unless respond_to?(underscored_column_name)
          self.class.send :define_method, underscored_column_name do
            @attributes[column.name]
          end
        end
      end
    end
    
    def initialize_values(columns)
      @attributes = {}
      columns.each do |column|
        @attributes[column.name] = case column.type
        when 'N' # number
          column.decimal.zero? ? unpack_string(column).to_i : unpack_string(column).to_f
        when 'D' # date
          raw = unpack_string(column).strip
          unless raw.empty?
            parts = raw.match(DATE_REGEXP).captures.map {|n| n.to_i}
            begin
              Time.gm(*parts)
            rescue
              Date.new(*parts)
            end
          end
        when 'M' # memo
          starting_block = unpack_string(column).to_i
          read_memo(starting_block)
        when 'L' # logical
          unpack_string(column) =~ /^(y|t)$/i ? true : false
        when 'I' # integer
          unpack_integer(column)
        when 'T' # datetime
          unpack_datetime(column)
        else
          unpack_string(column).strip
        end
        @attributes[underscore(column.name)] = @attributes[column.name]
        @attributes
      end
    end
  
    def unpack_column(column)
      @data.read(column.length).to_s.unpack("a#{column.length}")
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
      return nil if !@table.has_memo_file? || start_block < 1

      @table.memo_file_format == :fpt ? build_fpt_memo(start_block) : build_dbt_memo(start_block)
    end
    
    def build_fpt_memo(start_block)
      @memo.seek(start_block * memo_block_size)
      
      memo_type, memo_size, memo_string = @memo.read(memo_block_size).unpack("NNa56")
      return nil unless memo_type == 1 and memo_size > 0
      
      if memo_size > memo_block_content_size
        memo_string << @memo.read(memo_content_size(memo_size))
      else
        memo_string = memo_string[0, memo_size]
      end
      memo_string
    end
    
    def build_dbt_memo(start_block)
      @memo.seek(start_block * memo_block_size)
      
      case @table.version
      when "83" # dbase iii
        memo_string = ""
        loop do
          memo_string << block = @memo.read(memo_block_size)
          break if block.rstrip.size < memo_block_size
        end
      when "8b" # dbase iv
        memo_type, memo_size = @memo.read(BLOCK_HEADER_SIZE).unpack("LL")
        memo_string = @memo.read(memo_size)
      end
      memo_string
    end
    
    def memo_block_size
      @memo_block_size ||= @table.memo_block_size
    end
    
    def memo_block_content_size
      memo_block_size - BLOCK_HEADER_SIZE
    end
    
    def memo_content_size(memo_size)
      (memo_size - memo_block_size) + BLOCK_HEADER_SIZE
    end
    
  end
end