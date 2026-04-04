# frozen_string_literal: true

module DBF
  class VersionConfig
    DBASE2_HEADER_SIZE = 8
    DBASE3_HEADER_SIZE = 32
    DBASE7_HEADER_SIZE = 68

    VERSIONS = {
      '02' => 'FoxBase',
      '03' => 'dBase III without memo file',
      '04' => 'dBase IV without memo file',
      '05' => 'dBase V without memo file',
      '07' => 'Visual Objects 1.x',
      '30' => 'Visual FoxPro',
      '32' => 'Visual FoxPro with field type Varchar or Varbinary',
      '31' => 'Visual FoxPro with AutoIncrement field',
      '43' => 'dBASE IV SQL table files, no memo',
      '63' => 'dBASE IV SQL system files, no memo',
      '7b' => 'dBase IV with memo file',
      '83' => 'dBase III with memo file',
      '87' => 'Visual Objects 1.x with memo file',
      '8b' => 'dBase IV with memo file',
      '8c' => 'dBase 7',
      '8e' => 'dBase IV with SQL table',
      'cb' => 'dBASE IV SQL table files, with memo',
      'f5' => 'FoxPro with memo file',
      'fb' => 'FoxPro without memo file'
    }.freeze

    FOXPRO_VERSIONS = {
      '30' => 'Visual FoxPro',
      '31' => 'Visual FoxPro with AutoIncrement field',
      'f5' => 'FoxPro with memo file',
      'fb' => 'FoxPro without memo file'
    }.freeze

    attr_reader :version

    def initialize(version)
      @version = version
    end

    def version_description
      VERSIONS[version]
    end

    def header_size
      case version
      when '02'
        DBASE2_HEADER_SIZE
      when '04', '8c'
        DBASE7_HEADER_SIZE
      else
        DBASE3_HEADER_SIZE
      end
    end

    def foxpro?
      FOXPRO_VERSIONS.key?(version)
    end

    def memo_class
      if foxpro?
        Memo::Foxpro
      else
        version == '83' ? Memo::Dbase3 : Memo::Dbase4
      end
    end

    def read_column_args(table, io)
      case version
      when '02' then [table, *io.read(header_size * 2).unpack('A11 a C'), 0]
      when '04', '8c' then [table, *io.read(48).unpack('A32 a C C x13')]
      else [table, *io.read(header_size).unpack('A11 a x4 C2')]
      end
    end
  end
end
