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
end
