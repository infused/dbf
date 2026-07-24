# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'tmpdir'

# Regression tests for security fixes. Each group forges malformed xBase bytes
# and asserts the parser degrades safely rather than injecting code, escaping
# the database directory, over-allocating, looping unboundedly, or crashing on
# a nil read.
RSpec.describe 'DBF security' do # rubocop:disable RSpec/DescribeClass, RSpec/SpecFilePathFormat
  def dbf_header(version: 0x03, record_count: 0, header_length: 0, record_length: 0)
    bytes = (+"\x00").b * 32
    bytes.setbyte(0, version)
    bytes[4, 4] = [record_count].pack('V')
    bytes[8, 2] = [header_length].pack('v')
    bytes[10, 2] = [record_length].pack('v')
    bytes
  end

  def dbf_column(name: 'COL1', type: 'C', length: 10, decimal: 0)
    bytes = (+"\x00").b * 32
    encoded = name.b[0, 11]
    bytes[0, encoded.bytesize] = encoded
    bytes.setbyte(11, type.ord)
    bytes.setbyte(16, length & 0xFF)
    bytes.setbyte(17, decimal & 0xFF)
    bytes
  end

  def dbf_table(version: 0x03, record_count: 0, record_length: 0, columns: nil, records: '')
    descriptors = (columns || [dbf_column]).join
    header_length = 32 + descriptors.bytesize + 1
    dbf_header(version:, record_count:, header_length:, record_length:) +
      descriptors + "\x0D".b + records.b
  end

  # --- VULN-001 ---
  describe 'generated schema escaping (CWE-94)' do
    let(:hostile_table_name) { 'x", :evil => system("id")  #' }
    let(:bytes) { dbf_table(columns: [dbf_column(name: 'A"B', type: 'C', length: 5)]) }

    it 'escapes quotes in column names in the ActiveRecord schema' do
      table = DBF::Table.new(StringIO.new(bytes), nil, nil, name: 'safe')
      expect(table.schema(:activerecord)).to include 'a"b'.inspect
    end

    it 'escapes quotes in column names in the Sequel schema' do
      table = DBF::Table.new(StringIO.new(bytes), nil, nil, name: 'safe')
      expect(table.schema(:sequel)).to include 'a"b'.to_sym.inspect
    end

    it 'escapes a hostile table name in the ActiveRecord schema' do
      table = DBF::Table.new(StringIO.new(bytes), nil, nil, name: hostile_table_name)
      expect(table.schema(:activerecord)).to include hostile_table_name.inspect
    end

    it 'escapes a hostile table name in the Sequel schema' do
      table = DBF::Table.new(StringIO.new(bytes), nil, nil, name: hostile_table_name)
      expect(table.schema(:sequel)).to include hostile_table_name.to_sym.inspect
    end
  end

  # --- VULN-002 ---
  describe 'CSV formula injection (CWE-1236)' do
    def csv_for(bytes)
      io = StringIO.new(+'')
      DBF::Table.new(StringIO.new(bytes)).to_csv(io)
      io.string
    end

    it 'neutralizes a cell value that begins with a formula trigger' do
      bytes = dbf_table(record_count: 1, record_length: 6,
                        columns: [dbf_column(name: 'F', type: 'C', length: 5)],
                        records: ' =1+2 ')
      expect(csv_for(bytes)).to include %("'=1+2")
    end

    it 'neutralizes a column name that begins with a formula trigger' do
      bytes = dbf_table(record_count: 0, record_length: 6,
                        columns: [dbf_column(name: '=X', type: 'C', length: 5)])
      expect(csv_for(bytes)).to include %("'=X")
    end

    it 'does not raise on values whose bytes are invalid in the declared encoding' do
      bytes = dbf_table(record_count: 1, record_length: 6,
                        columns: [dbf_column(name: 'F', type: 'C', length: 5)],
                        records: " =\xFF\xFE\x9E\x8E".b)
      expect { csv_for(bytes) }.to_not raise_error
    end

    it 'still neutralizes a formula when later bytes are invalid' do
      bytes = dbf_table(record_count: 1, record_length: 6,
                        columns: [dbf_column(name: 'F', type: 'C', length: 5)],
                        records: " =\xFF\xFE\x9E\x8E".b)
      expect(csv_for(bytes)).to include "'="
    end

    it 'leaves ordinary values untouched' do
      bytes = dbf_table(record_count: 1, record_length: 6,
                        columns: [dbf_column(name: 'F', type: 'C', length: 5)],
                        records: ' safe ')
      expect(csv_for(bytes)).to include %("safe")
    end
  end

  # --- VULN-003 ---
  describe 'FoxPro .dbc table path traversal (CWE-22)' do
    let(:db) { DBF::Database::Foxpro.new fixture('foxprodb/FOXPRO-DB-TEST.DBC') }

    it 'refuses a container name that escapes the database directory' do
      Dir.mktmpdir do |dir|
        FileUtils.cp fixture('dbase_83.dbf'), File.join(dir, 'secret.dbf')
        outside = ('../' * 12) + File.join(dir, 'secret').sub(%r{\A/}, '')
        expect { db.table_path(outside) }.to raise_error(DBF::FileNotFoundError)
      end
    end

    it 'strips path separators rather than following them' do
      expect(db.table_path('../contacts')).to end_with File.join('foxprodb', 'contacts.dbf')
    end

    it 'still resolves a legitimate table name' do
      expect(db.table_path('contacts')).to end_with 'contacts.dbf'
    end
  end

  # --- VULN-004 ---
  describe 'FoxPro .dbc glob expansion (CWE-400)' do
    let(:db) { DBF::Database::Foxpro.new fixture('foxprodb/FOXPRO-DB-TEST.DBC') }

    it 'does not treat a wildcard in the name as a glob pattern' do
      expect { db.table_path('contact*') }.to raise_error(DBF::FileNotFoundError)
    end

    it 'does not expand brace groups in the name' do
      expect { db.table_path('{contacts,calls}') }.to raise_error(DBF::FileNotFoundError)
    end

    it 'still matches a legitimate name case-insensitively' do
      expect(db.table_path('CONTACTS')).to end_with 'contacts.dbf'
    end
  end

  # --- VULN-005 ---
  describe 'record buffer allocation bound (CWE-789)' do
    it 'does not allocate beyond the file for a crafted record count and length' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'crafted.dbf')
        File.binwrite(path, dbf_table(record_count: 4_294_967_295, record_length: 65_535,
                                      columns: [dbf_column(name: 'A', type: 'C', length: 10)]))
        File.open(path, 'rb') do |io|
          iterator = DBF::RecordIterator.new(io, nil, 32, 65_535, 4_294_967_295)
          expect(iterator.send(:read_buffer).bytesize).to be <= io.size
        end
      end
    end
  end

  # --- VULN-006 ---
  describe 'record iteration bound (CWE-835)' do
    it 'yields only the records actually present in the file' do
      bytes = dbf_table(record_count: 1_000_000, record_length: 10,
                        columns: [dbf_column(name: 'A', type: 'C', length: 9)],
                        records: " #{'x' * 9}")
      expect(DBF::Table.new(StringIO.new(bytes)).each.to_a.size).to eq 1
    end

    it 'yields nothing when the header declares a zero record length' do
      bytes = dbf_table(record_count: 1_000_000, record_length: 0,
                        columns: [dbf_column(name: 'A', type: 'C', length: 9)],
                        records: " #{'x' * 9}")
      expect(DBF::Table.new(StringIO.new(bytes)).each.to_a).to be_empty
    end
  end

  # --- VULN-007 ---
  describe 'dBase IV memo allocation bound (CWE-400)' do
    let(:data) { ("\x00".b * 512) + "\x00\x00\x00\x00#{[4_294_967_295].pack('L')}" + ('m'.b * 100) }

    it 'never reads more than the memo file holds' do
      io = StringIO.new(data)
      allow(io).to receive(:read).and_call_original
      DBF::Memo::Dbase4.new(io, '8b').get(1)
      expect(io).to_not have_received(:read).with(satisfy { |n| n.is_a?(Integer) && n > data.bytesize })
    end

    it 'still returns the memo content' do
      expect(DBF::Memo::Dbase4.new(StringIO.new(data), '8b').get(1)).to eq('m' * 100)
    end
  end

  # --- VULN-008 ---
  describe 'FoxPro memo allocation bound (CWE-400)' do
    let(:data) do
      bytes = (+"\x00").b * 1024
      bytes[6, 2] = [64].pack('n')
      bytes[64, 64] = [1, 4_294_967_295].pack('NN') + ('m'.b * 56)
      bytes
    end

    it 'never reads more than the memo file holds' do
      io = StringIO.new(data)
      allow(io).to receive(:read).and_call_original
      DBF::Memo::Foxpro.new(io, '30').get(1)
      expect(io).to_not have_received(:read).with(satisfy { |n| n.is_a?(Integer) && n > data.bytesize })
    end
  end

  # --- VULN-009 ---
  describe 'truncated header and column terminator (CWE-248)' do
    it 'returns no columns when the file ends before the column terminator' do
      bytes = dbf_header(record_count: 1, header_length: 32, record_length: 5)
      expect(DBF::Table.new(StringIO.new(bytes)).columns).to eq []
    end

    it 'tolerates an empty header read' do
      expect { DBF::Header.new(nil) }.to_not raise_error
    end

    it 'tolerates an empty file' do
      expect { DBF::Table.new(StringIO.new(+'')).columns }.to_not raise_error
    end

    it 'tolerates a header shorter than 32 bytes' do
      expect { DBF::Table.new(StringIO.new("\x03\x00\x00")).columns }.to_not raise_error
    end
  end

  # --- VULN-010 ---
  describe 'truncated numeric cells (CWE-248)' do
    it 'does not crash decoding a Currency cell shorter than its width' do
      bytes = dbf_table(record_count: 1, record_length: 3,
                        columns: [dbf_column(name: 'AMT', type: 'Y', length: 8, decimal: 4)],
                        records: ' ab')
      table = DBF::Table.new(StringIO.new(bytes))
      expect { table.each { |record| record&.to_a } }.to_not raise_error
    end

    it 'decodes a truncated AutoIncrement cell to nil' do
      bytes = dbf_table(record_count: 1, record_length: 3,
                        columns: [dbf_column(name: 'INC', type: '+', length: 4)],
                        records: ' ab')
      table = DBF::Table.new(StringIO.new(bytes))
      expect(table.each.to_a.first.to_a).to eq [nil]
    end
  end

  # --- VULN-011 ---
  describe 'truncated column descriptor (CWE-248)' do
    it 'stops column parsing instead of building an invalid column' do
      partial = ('N'.b * 11) + 'C'.b + ("\x00".b * 4)
      bytes = dbf_header(record_count: 1, header_length: 49, record_length: 5) + partial
      expect { DBF::Table.new(StringIO.new(bytes)).columns }.to_not raise_error
    end
  end

  # --- VULN-012 ---
  describe 'dBase III memo past EOF (CWE-248)' do
    it 'does not crash when the start block is past the end of the file' do
      memo = DBF::Memo::Dbase3.new(StringIO.new("\x00".b * 512), '83')
      expect { memo.get(99) }.to_not raise_error
    end
  end

  # --- VULN-013 ---
  describe 'dBase IV memo past EOF (CWE-248)' do
    it 'returns nil when the block header cannot be read' do
      memo = DBF::Memo::Dbase4.new(StringIO.new("\x00".b * 512), '8b')
      expect(memo.get(99)).to be_nil
    end
  end

  # --- VULN-014 ---
  describe 'FoxPro memo pointer on a truncated record (CWE-248)' do
    it 'does not crash when the record ends before the memo column' do
      bytes = dbf_table(version: 0x30, record_count: 1, record_length: 25,
                        columns: [dbf_column(name: 'A', type: 'C', length: 20),
                                  dbf_column(name: 'M', type: 'M', length: 4)],
                        records: "\x00XXXX")
      table = DBF::Table.new(StringIO.new(bytes), StringIO.new("\x00".b * 1024))
      expect { table.record(0)&.to_a }.to_not raise_error
    end
  end
end
