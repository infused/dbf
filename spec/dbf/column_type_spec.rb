# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DBF::ColumnType do
  StubColumn = Struct.new(:decimal, :encoding) unless defined?(StubColumn)

  def stub_column(decimal: 0, encoding: nil)
    StubColumn.new(decimal, encoding)
  end

  describe DBF::ColumnType::Nil do
    it 'returns nil regardless of input' do
      expect(described_class.new(stub_column).type_cast('whatever')).to be_nil
    end
  end

  describe DBF::ColumnType::Number do
    it 'casts to Integer when decimal is 0' do
      expect(described_class.new(stub_column).type_cast('42')).to eq 42
    end

    it 'casts to Float when decimal > 0' do
      expect(described_class.new(stub_column(decimal: 2)).type_cast('3.14')).to eq 3.14
    end

    it 'returns nil for an empty string' do
      expect(described_class.new(stub_column).type_cast('')).to be_nil
    end

    it 'has skip_blank? true' do
      expect(described_class.new(stub_column).skip_blank?).to be true
    end

    it 'decodes all-blank input as blank_value (nil)' do
      expect(described_class.new(stub_column).decode('     ')).to be_nil
    end
  end

  describe DBF::ColumnType::Currency do
    it 'unpacks a little-endian 64-bit value and divides by 10_000' do
      bytes = [10_000].pack('q<')
      expect(described_class.new(stub_column).type_cast(bytes)).to eq 1.0
    end

    it 'handles negative values' do
      bytes = [-25_000].pack('q<')
      expect(described_class.new(stub_column).type_cast(bytes)).to eq(-2.5)
    end
  end

  describe DBF::ColumnType::SignedLong do
    it 'unpacks a positive little-endian int32' do
      bytes = [123_456].pack('l<')
      expect(described_class.new(stub_column).type_cast(bytes)).to eq 123_456
    end

    it 'unpacks a negative little-endian int32' do
      bytes = [-1].pack('l<')
      expect(described_class.new(stub_column).type_cast(bytes)).to eq(-1)
    end
  end

  describe DBF::ColumnType::AutoIncrement do
    it 'returns a positive integer when the sign bit is set' do
      # bit 0 = '1' => sign_multiplier = 1
      bytes = [0b10000000_00000000_00000000_00000001].pack('N')
      expect(described_class.new(stub_column).type_cast(bytes)).to eq 1
    end

    it 'returns a negative integer when the sign bit is clear' do
      bytes = [0b00000000_00000000_00000000_00000001].pack('N')
      expect(described_class.new(stub_column).type_cast(bytes)).to eq(-1)
    end
  end

  describe DBF::ColumnType::Float do
    it 'casts to Float' do
      expect(described_class.new(stub_column).type_cast('1.5')).to eq 1.5
    end
  end

  describe DBF::ColumnType::Double do
    it 'unpacks a little-endian 64-bit float' do
      bytes = [2.5].pack('E')
      expect(described_class.new(stub_column).type_cast(bytes)).to eq 2.5
    end
  end

  describe DBF::ColumnType::Boolean do
    let(:bool) { described_class.new(stub_column) }

    it 'is true for Y/y/T/t' do
      %w[Y y T t].each { |c| expect(bool.type_cast(c)).to be true }
    end

    it 'is false for N/F/space' do
      %w[N F].each { |c| expect(bool.type_cast(c)).to be false }
    end

    it 'has blank_value = false and skip_blank? true' do
      expect(bool.blank_value).to be false
      expect(bool.skip_blank?).to be true
    end

    it 'decodes all-blank input to false' do
      expect(bool.decode('   ')).to be false
    end
  end

  describe DBF::ColumnType::Date do
    let(:date) { described_class.new(stub_column) }

    it 'parses a valid YYYYMMDD string' do
      expect(date.type_cast('20260523')).to eq Date.new(2026, 5, 23)
    end

    it 'returns nil for an invalid date string' do
      expect(date.type_cast('99999999')).to be_nil
    end

    it 'returns false from decode when input is blank' do
      expect(date.decode('        ')).to be false
    end
  end

  describe DBF::ColumnType::DateTime do
    let(:dt) { described_class.new(stub_column) }

    it 'returns nil for malformed input' do
      expect(dt.type_cast("\x00")).to be_nil
    end

    it 'returns a Time for valid JD+millis input' do
      bytes = [2_460_184, 12 * 3_600_000].pack('l2') # noon UTC
      expect(dt.type_cast(bytes)).to be_a(Time)
    end
  end

  describe DBF::ColumnType::Memo do
    it 'yields the raw value and casts the block result' do
      memo = described_class.new(stub_column)
      expect(memo.decode('ref') { |raw| "got:#{raw}" }).to eq 'got:ref'
    end

    it 'returns nil when the block yields nil' do
      memo = described_class.new(stub_column)
      expect(memo.decode('ref') { nil }).to be_nil
    end

    it 're-encodes content when encoding is set' do
      memo = described_class.new(stub_column(encoding: 'cp1251'))
      raw = "\xE0".b # 'а' in cp1251
      result = memo.decode('ref') { raw.dup }
      expect(result.encoding).to eq Encoding.default_external
    end

    it 'returns the value unchanged when encoding is nil' do
      memo = described_class.new(stub_column)
      expect(memo.decode('ref') { 'plain' }).to eq 'plain'
    end
  end

  describe DBF::ColumnType::General do
    it 'forces ASCII-8BIT encoding' do
      result = described_class.new(stub_column).type_cast('hello')
      expect(result.encoding).to eq Encoding::ASCII_8BIT
    end

    it 'passes nil through' do
      expect(described_class.new(stub_column).type_cast(nil)).to be_nil
    end
  end

  describe DBF::ColumnType::String do
    it 'strips whitespace' do
      expect(described_class.new(stub_column).type_cast(+'  hi  ')).to eq 'hi'
    end

    it 'encodes when source encoding differs from default_external' do
      result = described_class.new(stub_column(encoding: 'cp1251')).type_cast("\xE0".b.dup)
      expect(result.encoding).to eq Encoding.default_external
    end

    it 'has blank_value = ""' do
      expect(described_class.new(stub_column).blank_value).to eq ''
    end

    it 'decodes all-blank input to ""' do
      expect(described_class.new(stub_column).decode('    ')).to eq ''
    end
  end
end
