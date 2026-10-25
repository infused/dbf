# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DBF::ColumnBuilder do
  describe '#build with a dBase 3 fixture' do
    let(:table) { DBF::Table.new fixture('dbase_83.dbf') }

    it 'returns an Array of DBF::Column instances' do
      expect(table.columns).to be_an(Array)
      expect(table.columns).to all be_a(DBF::Column)
    end

    it 'parses every column up to the 0x0D terminator' do
      expect(table.columns.size).to eq 15
    end

    it 'restores the io position after building' do
      File.open(fixture('dbase_83.dbf'), 'rb') do |io|
        io.seek(0)
        original_pos = io.pos
        version_config = DBF::VersionConfig.new('83')
        DBF::ColumnBuilder.new(table, io, version_config).build
        expect(io.pos).to eq original_pos
      end
    end
  end

  describe '#build with a Visual FoxPro fixture' do
    let(:table) { DBF::Table.new fixture('dbase_30.dbf') }

    it 'parses FoxPro columns without raising' do
      expect(table.columns).to all be_a(DBF::Column)
    end

    it 'returns the expected column count' do
      expect(table.columns.size).to be > 0
    end
  end

  describe '#build when columns do not fit' do
    # dbase_83.dbf with its header or record length field overwritten
    def table_with(offset, value)
      bytes = File.binread(fixture('dbase_83.dbf'))
      bytes[offset, 2] = [value].pack('v')
      DBF::Table.new(StringIO.new(bytes))
    end

    it 'warns that it ignored the descriptors past header_length' do
      table = table_with(8, 32 + (3 * 32) + 1)
      expect { table.columns }
        .to output("DBF: ignored the columns after the first 3: they do not fit within the header length of 129 bytes\n").to_stderr
      expect(table.columns.size).to eq 3
    end

    it 'warns that it ignored the columns wider than record_length' do
      table = table_with(10, 40)
      expect { table.columns }
        .to output("DBF: ignored the columns after the first 2: they do not fit within the record length of 40 bytes\n").to_stderr
      expect(table.columns.size).to eq 2
    end

    it 'does not warn when $VERBOSE is nil' do
      table = table_with(10, 40)
      verbose = $VERBOSE
      $VERBOSE = nil
      expect { table.columns }.to_not output.to_stderr
    ensure
      $VERBOSE = verbose
    end

    it 'does not warn for any well-formed fixture' do
      paths = Dir[File.join(fixture_path, '**', '*.{dbf,DBC}')]
      expect(paths.size).to eq 19
      expect { paths.each { |path| DBF::Table.open(path, &:columns) } }.to_not output.to_stderr
    end
  end
end
