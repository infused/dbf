# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DBF::Header do
  def read_header_bytes(filename, size = 32)
    File.open(fixture(filename), 'rb') { |f| f.read(size) }
  end

  describe 'version 02 (FoxBase)' do
    let(:bytes) { read_header_bytes('dbase_02.dbf', 8) }
    let(:header) { described_class.new(bytes) }

    it 'reads the version' do
      expect(header.version).to eq '02'
    end

    it 'fixes the header_length at 521' do
      expect(header.header_length).to eq 521
    end

    it 'reads the record count' do
      expect(header.record_count).to eq 9
    end

    it 'reads the record length' do
      expect(header.record_length).to be_a(Integer)
      expect(header.record_length).to be > 0
    end

    it 'leaves encoding_key nil' do
      expect(header.encoding_key).to be_nil
    end

    it 'leaves encoding nil' do
      expect(header.encoding).to be_nil
    end
  end

  describe 'version 83 (dBase III with memo)' do
    let(:bytes) { read_header_bytes('dbase_83.dbf') }
    let(:header) { described_class.new(bytes) }

    it 'reads the version' do
      expect(header.version).to eq '83'
    end

    it 'reads the record count' do
      expect(header.record_count).to eq 67
    end

    it 'reads the header length' do
      expect(header.header_length).to be > 32
    end

    it 'reads the record length' do
      expect(header.record_length).to be > 0
    end

    it 'reads the encoding_key as a 2-char hex string' do
      expect(header.encoding_key).to be_a(String)
      expect(header.encoding_key.length).to eq 2
    end
  end

  describe 'version 30 (Visual FoxPro)' do
    let(:bytes) { read_header_bytes('dbase_30.dbf') }
    let(:header) { described_class.new(bytes) }

    it 'reads the version' do
      expect(header.version).to eq '30'
    end

    it 'reads the record count' do
      expect(header.record_count).to eq 34
    end
  end

  describe 'with cp1251 embedded encoding' do
    let(:bytes) { read_header_bytes('cp1251.dbf') }
    let(:header) { described_class.new(bytes) }

    it 'resolves encoding via the ENCODINGS lookup' do
      expect(header.encoding).to eq 'cp1251'
    end
  end

  describe 'with an unknown encoding_key' do
    let(:bytes) do
      buf = read_header_bytes('dbase_83.dbf').dup
      buf[29] = "\xFE".b
      buf
    end
    let(:header) { described_class.new(bytes) }

    it 'still parses the version' do
      expect(header.version).to eq '83'
    end

    it 'leaves encoding nil when key is not in ENCODINGS' do
      expect(header.encoding).to be_nil
    end
  end

  describe 'across all available fixture versions' do
    %w[dbase_03.dbf dbase_8b.dbf dbase_8c.dbf dbase_31.dbf dbase_32.dbf dbase_f5.dbf].each do |fixture_name|
      it "parses #{fixture_name} without raising" do
        expect { described_class.new(read_header_bytes(fixture_name)) }.to_not raise_error
      end
    end
  end
end
