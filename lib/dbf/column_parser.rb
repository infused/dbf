# frozen_string_literal: true

module DBF
  class ColumnParser
    def self.data_size_for_version(version, header_size)
      case version
      when '02'
        header_size * 2
      when '04', '8c'
        48
      else
        header_size
      end
    end

    def self.parse_column_data(raw_data, version)
      case version
      when '02'
        raw_data.unpack('A11 a C')
      when '04', '8c'
        raw_data.unpack('A32 a C C x13')
      else
        raw_data.unpack('A11 a x4 C2')
      end
    end

    def self.build_column_args(table, parsed_data, version)
      case version
      when '02'
        [table, *parsed_data, 0]
      when '04', '8c'
        [table, *parsed_data]
      else
        [table, *parsed_data]
      end
    end
  end
end