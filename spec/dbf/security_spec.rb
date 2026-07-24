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

end
