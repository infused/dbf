# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'DBF::Table' do
  context 'with default encoding' do
    let(:dbf_path) { fixture('dbase_03_cyrillic.dbf') }
    let(:table) { DBF::Table.new dbf_path }
  
    it 'defaults to UTF-8 encoding' do
      expect(table.encoding).to eq Encoding::UTF_8
    end
  
    it 'uses the table encoding for column encoding' do
      column = table.columns.first
      expect(column.encoding).to eq table.encoding
    end
  
    it 'encodes column names' do
      expect(table.column_names).to eq %w[ШАР ПЛОЩА]
    end
  
    it 'encodes record values' do
      expect(table.record(0).attributes['ШАР']).to eq 'Номер'
    end
  end

  context 'with embedded encoding' do
    let(:dbf_path) { fixture('cp1251.dbf') }
    let(:table) { DBF::Table.new dbf_path }
  
    it 'defaults to UTF-8 encoding' do
      expect(table.encoding).to eq 'cp1251'
    end
  
    it 'uses the table encoding for column encoding' do
      column = table.columns.first
      expect(column.encoding).to eq table.encoding
    end
  
    it 'encodes column names' do
      expect(table.column_names).to eq %w[RN NAME]
    end
  
    it 'encodes record values' do
      expect(table.record(0).attributes['NAME']).to eq 'амбулаторно-поликлиническое'
    end
  end

  context 'with embedded Mazovia (cp620) encoding' do
    let(:dbf_path) { fixture('mazovia.dbf') }
    let(:table) { DBF::Table.new dbf_path }

    it 'reads the encoding from the header' do
      expect(table.encoding).to eq 'cp620'
    end

    it 'encodes column names' do
      expect(table.column_names).to eq %w[A1 A2]
    end

    it 'encodes record values' do
      expect(table.record(0).attributes['A2']).to eq 'English'
      expect(table.record(1).attributes['A2']).to eq 'Ś╫êëτ⌡ś'
    end
  end

  context 'with embedded Kamenicky (cp895) encoding' do
    let(:field_bytes) { +"P\xa9\xa1li\xa8" }
    let(:table) { DBF::Table.new StringIO.new(build_dbf('68', field_bytes)) }

    it 'reads the encoding from the header' do
      expect(table.encoding).to eq 'cp895'
    end

    it 'encodes record values' do
      expect(table.record(0).attributes['NAME']).to eq 'Příliš'
    end
  end

  context 'with a custom code page passed as user encoding' do
    let(:dbf_path) { fixture('dbase_03_cyrillic.dbf') }
    let(:table) { DBF::Table.new dbf_path, nil, 'cp620' }

    it 'uses the user encoding' do
      expect(table.encoding).to eq 'cp620'
    end
  end

  describe 'DBF::ENCODINGS' do
    it 'contains only resolvable encodings' do
      DBF::ENCODINGS.each_value do |name|
        resolvable = DBF::Encoder.custom?(name) || !Encoding.find(name).nil?
        expect(resolvable).to be(true), "expected #{name} to be a Ruby encoding or a custom code page"
      end
    end
  end

  def build_dbf(language_driver_hex, field_bytes)
    field_length = field_bytes.bytesize
    header = [0x03, 26, 7, 9, 1, 32 + 32 + 1, 1 + field_length].pack('C4Vv2')
    header << ([0] * 17).pack('C17') << [language_driver_hex].pack('H2') << "\x00\x00"
    column = [+'NAME', 'C'].pack('a11a1') << ([0] * 4).pack('C4') << [field_length, 0].pack('C2') << ([0] * 14).pack('C14')
    header << column << "\x0d" << ' ' << field_bytes << "\x1a"
  end
end
