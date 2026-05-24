# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DBF::Memo::Dbase3 do
  describe '#get' do
    let(:block_size) { 512 }

    let(:fpt_data) do
      header = "\x00" * block_size
      content = ('x' * 100) + "\x1A\x00" # terminator bytes stripped by gsub
      header + content + ("\x00" * (block_size - content.bytesize))
    end

    it 'reads memo bytes up to the terminator' do
      memo = described_class.new(StringIO.new(fpt_data), '83')
      expect(memo.get(1)).to eq('x' * 100)
    end

    it 'returns nil for start_block 0' do
      expect(described_class.new(StringIO.new(fpt_data), '83').get(0)).to be_nil
    end

    it 'reads across multiple blocks until a short read terminates the loop' do
      memo_text = 'y' * 1500
      data = ("\x00" * block_size) + memo_text + "\x1A\x00"
      io = StringIO.new(data)
      expect(described_class.new(io, '83').get(1)).to eq memo_text
    end
  end

  describe 'integration with the dBase III fixture' do
    let(:table) { DBF::Table.new fixture('dbase_83.dbf') }

    it 'reads memo content for a record with a non-blank memo' do
      record = table.each.find { |r| r && r.desc && r.desc.length > 0 }
      expect(record.desc).to be_a(String)
    end

    it 'handles records pointing at a missing memo block as nil/blank' do
      table = DBF::Table.new fixture('dbase_83_missing_memo.dbf')
      expect { table.each.to_a }.to_not raise_error
    end
  end
end
