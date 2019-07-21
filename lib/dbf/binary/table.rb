# encoding ascii-8bit

module DBF
  module Binary
    class Table < BinData::Record
      endian :little

      # The size of the header up to (but not including) the field descriptors
      FILE_HEADER_SIZE = 32

      uint8 :_version                           # byte offset 0
      struct :_last_update do                   # byte offset 1-3
        uint8 :year
        uint8 :month
        uint8 :day
      end

      # Number of records in file (32-bit number)
      uint32 :record_count                      # byte offset 4-7

      # Number of bytes in header (16-bit number)
      uint16 :header_length                     # byte offset 8-9

      # Number of bytes in record (16-bit number)
      uint16 :record_length                     # byte offset 10-11

      # Reserved, fill with 0x00
      skip length: 2                            # byte offset 12-13

      # dBaseIV flag, incomplete transaction
      # 0x01 Begin Transaction
      # 0x00 End Transaction or RollBack
      uint8 :incomplete_transaction             # byte offset 14

      # Encryption flag
      # 0x01 Encrypted
      # 0x00 Not Encrypted
      uint8 :_encrypted                         # byte offset 15

      # dBaseIV multi-user environment use
      skip length: 12                           # byte offset 16-27

      # 0x01 Production index exists (only dBase 4/5)
      # 0x00 Index on demand (all xBase versions)
      uint8 :table_flag                         # byte offset 28
      uint8 :code_page_mark                     # byte offset 29

      # Reserved, full with 0x00
      skip length: 2                            # byte offset 30-31

      array :columns, type: :column, initial_length: :field_count

      def version
        @version ||= _version.to_i.to_s(16).rjust(2, '0')
      end

      def encoding_key
        @encoding_key ||= code_page_mark.to_i.to_s(16).rjust(2, '0')
      end

      def encoding
        @encoding ||= DBF::ENCODINGS[encoding_key]
      end

      def last_update
        Date.new _last_update.year, _last_update.month, _last_update.day
      end

      def encrypted
        !_encrypted.zero?
      end

      def field_count
        @field_count ||= (header_length - FILE_HEADER_SIZE) / FILE_HEADER_SIZE
      end
    end
  end
end
