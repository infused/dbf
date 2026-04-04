# frozen_string_literal: true

module DBF
  # An instance of DBF::Record represents a row in the DBF file
  class Record
    # Initialize a new DBF::Record
    #
    # @param data [String, StringIO] data
    # @param context [DBF::RecordContext]
    # @param offset [Integer]
    def initialize(data, context, offset = 0)
      @data = data
      @context = context
      @offset = offset
      @to_a = nil
    end

    # Equality
    #
    # @param [DBF::Record] other
    # @return [Boolean]
    def ==(other)
      attributes == other.attributes
    rescue NoMethodError
      false
    end

    # Reads attributes by column name
    #
    # @param name [String, Symbol] key
    def [](name)
      key = name.to_s
      if @context.column_offsets && !@to_a
        index = column_name_index(key)
        index ? column_value(index) : nil
      elsif attributes.key?(key)
        attributes[key]
      elsif (index = underscored_column_names.index(key))
        attributes[@context.columns[index].name]
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
        columns = @context.columns
        col_count = columns.length
        result = Array.new(col_count)
        index = 0
        while index < col_count
          column = columns[index]
          len = column.length
          raw = data.byteslice(offset, len)
          offset += len
          result[index] = decode_column(raw, column)
          index += 1
        end
        @offset = offset
        result
      end
    end

    private

    def decode_memo_value(raw) # :nodoc:
      memo = @context.memo
      return nil unless memo

      version = @context.version
      raw = raw.unpack1('V') if version == '30' || version == '31'
      memo.get(raw.to_i)
    end

    def column_name_index(key) # :nodoc:
      column_names.index(key) || underscored_column_names.index(key)
    end

    def column_value(index) # :nodoc:
      column = @context.columns[index]
      col_offset = @offset + @context.column_offsets[index]
      len = column.length
      raw = @data.byteslice(col_offset, len)
      decode_column(raw, column)
    end

    def decode_column(raw, column) # :nodoc:
      column.decode(raw) { |raw_memo| decode_memo_value(raw_memo) }
    end

    def column_names # :nodoc:
      @column_names ||= @context.columns.map(&:name)
    end

    def method_missing(method, *args) # :nodoc:
      key = method.to_s
      if (index = underscored_column_names.index(key))
        if @context.column_offsets && !@to_a
          column_value(index)
        else
          attributes[@context.columns[index].name]
        end
      else
        super
      end
    end

    def respond_to_missing?(method, *) # :nodoc:
      underscored_column_names.include?(method.to_s) || super
    end

    def underscored_column_names # :nodoc:
      @underscored_column_names ||= @context.columns.map(&:underscored_name)
    end
  end
end
