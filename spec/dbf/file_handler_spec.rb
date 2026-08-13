# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'

RSpec.describe DBF::FileHandler do
  describe '.open_data' do
    it 'returns the same StringIO when given a StringIO' do
      io = StringIO.new('data')
      expect(described_class.open_data(io)).to be(io)
    end

    it 'opens a File in binary mode when given a path string' do
      result = described_class.open_data(fixture('dbase_83.dbf'))
      expect(result).to be_a(File)
      expect(result.binmode?).to be true
      result.close
    end

    it 'raises DBF::FileNotFoundError when path does not exist' do
      expect { described_class.open_data('does_not_exist.dbf') }
        .to raise_error(DBF::FileNotFoundError, 'file not found: does_not_exist.dbf')
    end

    it 'returns the same File when given a File, switched to binary mode' do
      File.open(fixture('dbase_83.dbf')) do |file|
        expect(described_class.open_data(file)).to be(file)
        expect(file.binmode?).to be true
      end
    end

    it 'raises ArgumentError when given nil' do
      expect { described_class.open_data(nil) }
        .to raise_error(ArgumentError, 'data must be a file path or an IO-like object responding to #read and #seek')
    end

    it 'raises ArgumentError when given an unsupported type' do
      expect { described_class.open_data(42) }
        .to raise_error(ArgumentError, 'data must be a file path or an IO-like object responding to #read and #seek')
    end
  end

  describe '.data_path' do
    it 'returns the string itself for a path' do
      expect(described_class.data_path('a.dbf')).to eq 'a.dbf'
    end

    it 'returns the path of an IO that has one' do
      File.open(fixture('dbase_83.dbf')) do |file|
        expect(described_class.data_path(file)).to eq fixture('dbase_83.dbf')
      end
    end

    it 'returns nil for an IO without a path' do
      expect(described_class.data_path(StringIO.new)).to be_nil
    end
  end

  describe '.open_memo' do
    let(:memo_class) { class_double(DBF::Memo::Dbase3) }

    it 'returns nil when memo is nil and data is a StringIO' do
      expect(described_class.open_memo(StringIO.new, nil, memo_class, '83')).to be_nil
    end

    it 'returns nil when no memo file is found alongside the data path' do
      Dir.mktmpdir do |dir|
        dbf = File.join(dir, 'standalone.dbf')
        File.write(dbf, '')
        expect(described_class.open_memo(dbf, nil, memo_class, '83')).to be_nil
      end
    end

    it 'opens the memo via memo_class.open when a path is given' do
      allow(memo_class).to receive(:open).with('/tmp/m.dbt', '83').and_return(:opened)
      expect(described_class.open_memo('any.dbf', '/tmp/m.dbt', memo_class, '83')).to eq(:opened)
    end

    it 'instantiates the memo via memo_class.new when a StringIO is given' do
      io = StringIO.new
      allow(memo_class).to receive(:new).with(io, '83').and_return(:built)
      expect(described_class.open_memo('any.dbf', io, memo_class, '83')).to eq(:built)
    end

    it 'auto-discovers a memo file next to the data path' do
      allow(memo_class).to receive(:open).with(fixture('dbase_83.dbt'), '83').and_return(:opened)
      expect(described_class.open_memo(fixture('dbase_83.dbf'), nil, memo_class, '83')).to eq(:opened)
    end

    it 'auto-discovers a memo file next to a File object' do
      allow(memo_class).to receive(:open).with(fixture('dbase_83.dbt'), '83').and_return(:opened)
      File.open(fixture('dbase_83.dbf')) do |file|
        expect(described_class.open_memo(file, nil, memo_class, '83')).to eq(:opened)
      end
    end

    it 'instantiates the memo via memo_class.new when an IO is given' do
      File.open(fixture('dbase_83.dbt')) do |file|
        allow(memo_class).to receive(:new).with(file, '83').and_return(:built)
        expect(described_class.open_memo('any.dbf', file, memo_class, '83')).to eq(:built)
      end
    end
  end

  describe '.memo_search_path' do
    it 'builds a glob covering .fpt/.FPT/.dbt/.DBT siblings' do
      path = described_class.memo_search_path('/data/foo.dbf')
      expect(path).to eq '/data/foo*.{fpt,FPT,dbt,DBT}'
    end
  end
end
