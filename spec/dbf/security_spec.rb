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

end
