module DBF
  class FieldLengthError < DBFError; end
  
  class Field
    attr_reader :name, :type, :length, :decimal

    def initialize(name, type, length, decimal)
      raise FieldLengthError, "field length must be greater than 0" unless length > 0
      @name, @type, @length, @decimal = name.gsub(/\0/, ''), type, length, decimal
    end
  end
end