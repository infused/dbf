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
end
