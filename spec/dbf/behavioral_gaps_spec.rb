# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DBF::Table do # rubocop:disable RSpec/SpecFilePathFormat
  describe 'user-supplied encoding overrides header encoding' do
    let(:dbf_path) { fixture('cp1251.dbf') }

    it 'wins over the header-declared encoding' do
      table = DBF::Table.new dbf_path, nil, Encoding::US_ASCII
      expect(table.encoding).to eq Encoding::US_ASCII
    end

    it 'is applied to columns' do
      table = DBF::Table.new dbf_path, nil, 'cp866'
      expect(table.columns.first.encoding).to eq 'cp866'
    end
  end

  describe 'header parsing with an unknown encoding key' do
    let(:bytes) do
      buf = File.read(fixture('dbase_83.dbf'))[0, 32].b.dup
      buf[29] = "\xFE".b
      buf
    end

    it 'leaves Header#encoding nil rather than raising' do
      header = DBF::Header.new(bytes)
      expect(header.encoding).to be_nil
    end
  end

  describe 'reading after #close' do
    let(:table) { DBF::Table.new fixture('dbase_83.dbf') }

    it 'raises IOError when accessing records' do
      table.close
      expect { table.record(0) }.to raise_error(IOError)
    end

    it 'closed? is true after close' do
      table.close
      expect(table.closed?).to be true
    end
  end

  describe '#each without a block returns an Enumerator' do
    let(:table) { DBF::Table.new fixture('dbase_83.dbf') }

    it 'is enumerable' do
      enum = table.each
      expect(enum).to be_a(Enumerator)
      expect(enum.to_a.size).to eq table.record_count
    end
  end

  describe '#each when columns are empty' do
    let(:table) { DBF::Table.new fixture('polygon.dbf') }

    it 'yields nothing rather than raising' do
      expect { table.each { |record| record } }.to_not raise_error
    end
  end

  describe 'rare format version descriptions' do
    %w[04 05 07 43 63 7b 87 8e cb fb].each do |version_byte|
      it "returns a description for version #{version_byte}" do
        config = DBF::VersionConfig.new(version_byte)
        expect(config.version_description).to be_a(String)
        expect(config.version_description).to_not be_empty
      end
    end

    it 'returns nil for an unknown version' do
      expect(DBF::VersionConfig.new('zz').version_description).to be_nil
    end

    it 'foxpro? matches the FOXPRO_VERSIONS set' do
      %w[30 31 f5 fb].each { |v| expect(DBF::VersionConfig.new(v).foxpro?).to be true }
      %w[02 03 83 8b].each { |v| expect(DBF::VersionConfig.new(v).foxpro?).to be false }
    end

    it 'selects Memo::Foxpro for FoxPro versions' do
      expect(DBF::VersionConfig.new('30').memo_class).to eq DBF::Memo::Foxpro
    end

    it 'selects Memo::Dbase3 for version 83 and Memo::Dbase4 for other non-FoxPro' do
      expect(DBF::VersionConfig.new('83').memo_class).to eq DBF::Memo::Dbase3
      expect(DBF::VersionConfig.new('8b').memo_class).to eq DBF::Memo::Dbase4
    end

    it 'reports the correct header_size for each variant' do
      expect(DBF::VersionConfig.new('02').header_size).to eq DBF::VersionConfig::DBASE2_HEADER_SIZE
      expect(DBF::VersionConfig.new('04').header_size).to eq DBF::VersionConfig::DBASE7_HEADER_SIZE
      expect(DBF::VersionConfig.new('8c').header_size).to eq DBF::VersionConfig::DBASE7_HEADER_SIZE
      expect(DBF::VersionConfig.new('83').header_size).to eq DBF::VersionConfig::DBASE3_HEADER_SIZE
    end
  end

  describe 'CSV export to a file' do
    let(:table) { DBF::Table.new fixture('dbase_83.dbf') }
    let(:path) { 'tmp_export.csv' }

    after { FileUtils.rm_f path }

    it 'writes a header row followed by record rows' do
      table.to_csv(path)
      content = File.read(path)
      expect(content).to start_with '"ID"'
      parsed = CSV.parse(content)
      expect(parsed.first.first).to eq 'ID'
      expect(parsed.size).to be > 1
    end
  end

  describe 'Record equality and attributes' do
    let(:table) { DBF::Table.new fixture('dbase_83.dbf') }

    it 'considers two records with identical attributes equal' do
      r1 = table.record(0)
      r2 = table.record(0)
      expect(r1).to eq r2
    end

    it 'exposes column values via attributes hash' do
      record = table.record(0)
      expect(record.attributes).to be_a(Hash)
      expect(record.attributes.keys).to include('ID')
    end
  end
end
