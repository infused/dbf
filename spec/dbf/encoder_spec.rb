# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DBF::Encoder do
  describe 'codepoint tables' do
    [DBF::Encoder::CP620_TO_UNICODE, DBF::Encoder::CP895_TO_UNICODE].each do |table|
      it 'has 256 entries' do
        expect(table.size).to eq 256
      end

      it 'is identity for the ASCII range' do
        expect(table[0..0x7f]).to eq (0..0x7f).to_a
      end
    end

    it 'maps known Mazovia high bytes' do
      expect(DBF::Encoder::CP620_TO_UNICODE[0x98].chr(Encoding::UTF_8)).to eq 'Ś'
      expect(DBF::Encoder::CP620_TO_UNICODE[0x9e].chr(Encoding::UTF_8)).to eq 'ś'
    end

    it 'maps known Kamenicky high bytes' do
      expect(DBF::Encoder::CP895_TO_UNICODE[0x87].chr(Encoding::UTF_8)).to eq 'č'
      expect(DBF::Encoder::CP895_TO_UNICODE[0x98].chr(Encoding::UTF_8)).to eq 'ý'
    end
  end

  describe '.custom?' do
    it 'is true for table-decoded code pages, case-insensitively' do
      expect(described_class.custom?('cp620')).to be true
      expect(described_class.custom?('CP895')).to be true
    end

    it 'is false for built-in encodings, Encoding objects and nil' do
      expect(described_class.custom?('cp1251')).to be false
      expect(described_class.custom?(Encoding::UTF_8)).to be false
      expect(described_class.custom?(nil)).to be false
    end
  end

  describe '.encode' do
    it 'decodes cp620 bytes to UTF-8' do
      expect(described_class.encode((+"\x98\xd7\x88\x89\xe7\xf5\x9e").force_encoding(Encoding::ASCII_8BIT), 'cp620')).to eq 'Ś╫êëτ⌡ś'
    end

    it 'decodes cp895 bytes to UTF-8' do
      expect(described_class.encode((+"P\xa9\xa1li\xa8").force_encoding(Encoding::ASCII_8BIT), 'cp895')).to eq 'Příliš'
    end

    it 'transcodes custom code pages to a non-UTF-8 target' do
      expect(described_class.encode(+"\x86", 'cp620', Encoding::ISO_8859_2)).to eq 'ą'.encode(Encoding::ISO_8859_2)
    end

    it 'matches the built-in force_encoding path for Ruby encodings' do
      bytes = +"\xe0\xe1\xe2"
      expected = bytes.dup.force_encoding('cp1251').encode(Encoding.default_external, undef: :replace, invalid: :replace)
      expect(described_class.encode(bytes.dup, 'cp1251')).to eq expected
    end

    it 'accepts Encoding objects for built-in encodings' do
      expect(described_class.encode(+'abc', Encoding::UTF_8)).to eq 'abc'
    end
  end
end
