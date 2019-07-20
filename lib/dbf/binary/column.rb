module DBF
  module Binary
    class Column < BinData::Record
      endian :little

      string :name, length: 11 , trim_padding: true, pad_byte: 0
      string :column_type, length:  1
      skip length: 4
      uint8 :column_length
      uint8 :decimal
      skip length: 14
    end
  end
end
