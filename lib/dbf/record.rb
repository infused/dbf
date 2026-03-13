# frozen_string_literal: true

module DBF
  # An instance of DBF::Record represents a row in the DBF file
  class Record
    # Initialize a new DBF::Record
    #
    # @param data [String, StringIO] data
    # @param columns [Column]
    # @param version [String]
    # @param memo [DBF::Memo]
    def initialize(data, columns, version, memo, offset = 0, column_offsets = nil)
      @data = data
      @offset = offset
      @columns = columns
      @version = version
      @memo = memo
      @column_offsets = column_offsets
    end

    # Equality
    #
    # @param [DBF::Record] other
    # @return [Boolean]
    def ==(other)
      other.respond_to?(:attributes) && other.attributes == attributes
    end

    # Reads attributes by column name
    #
    # @param name [String, Symbol] key
    def [](name)
      key = name.to_s
      if @to_a
        if attributes.key?(key)
          attributes[key]
        elsif (index = underscored_column_names.index(key))
          attributes[@columns[index].name]
        end
      elsif @column_offsets
        index = column_name_index(key)
        index ? column_value(index) : nil
      else
        if attributes.key?(key)
          attributes[key]
        elsif (index = underscored_column_names.index(key))
          attributes[@columns[index].name]
        end
      end
    end

    # Record attributes
    #
    # @return [Hash]
    def attributes
      @attributes ||= column_names.zip(to_a).to_h
    end

    # Do all search parameters match?
    #
    # @param [Hash] options
    # @return [Boolean]
    def match?(options)
      options.all? { |key, value| self[key] == value }
    end

    # Maps a row to an array of values
    #
    # @return [Array]
    def to_a
      @to_a ||= begin
        data = @data
        offset = @offset
        columns = @columns
        col_count = columns.length
        result = Array.new(col_count)
        i = 0
        while i < col_count
          column = columns[i]
          len = column.length
          if column.memo?
            if @memo
              memo_data = data.byteslice(offset, len)
              offset += len
              memo_data = memo_data.unpack1('V') if @version == '30' || @version == '31'
              result[i] = column.type_cast(@memo.get(memo_data.to_i))
            else
              offset += len
              result[i] = nil
            end
          else
            value = data.byteslice(offset, len)
            offset += len
            if column.skip_blank? && value.count(' ') == len
              result[i] = column.blank_value
            else
              result[i] = column.type_cast(value)
            end
          end
          i += 1
        end
        @offset = offset
        result
      end
    end

    private

    def column_name_index(key) # :nodoc:
      column_names.index(key) || underscored_column_names.index(key)
    end

    def column_value(index) # :nodoc:
      column = @columns[index]
      col_offset = @offset + @column_offsets[index]
      len = column.length

      if column.memo?
        if @memo
          memo_data = @data.byteslice(col_offset, len)
          memo_data = memo_data.unpack1('V') if @version == '30' || @version == '31'
          column.type_cast(@memo.get(memo_data.to_i))
        end
      else
        value = @data.byteslice(col_offset, len)
        if column.skip_blank? && value.count(' ') == len
          column.blank_value
        else
          column.type_cast(value)
        end
      end
    end

    def column_names # :nodoc:
      @column_names ||= @columns.map(&:name)
    end

    def method_missing(method, *args) # :nodoc:
      key = method.to_s
      if (index = underscored_column_names.index(key))
        if @to_a
          attributes[@columns[index].name]
        elsif @column_offsets
          column_value(index)
        else
          attributes[@columns[index].name]
        end
      else
        super
      end
    end

    def respond_to_missing?(method, *) # :nodoc:
      underscored_column_names.include?(method.to_s) || super
    end

    def underscored_column_names # :nodoc:
      @underscored_column_names ||= @columns.map(&:underscored_name)
    end
  end
end
