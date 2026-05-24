# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DBF::Memo::Dbase4 do
  describe '#get' do
    let(:block_size) { 512 } # base class BLOCK_SIZE
    let(:memo_text) { 'hello dBase IV memo' }

    let(:fpt_data) do
      # Block 0 is the header (unused by Dbase4 reader). Block 1 holds our memo.
      header = "\x00" * block_size
      # Dbase4 reads 8-byte block header and unpacks an unsigned long at offset 4
      block_header = "\x00\x00\x00\x00" + [memo_text.bytesize].pack('L')
      body = memo_text + ("\x00" * (block_size - block_header.bytesize - memo_text.bytesize))
      header + block_header + body
    end

    it 'reads the memo text at the given start block' do
      memo = described_class.new(StringIO.new(fpt_data), '8b')
      expect(memo.get(1)).to eq memo_text
    end

    it 'returns nil for start_block 0' do
      memo = described_class.new(StringIO.new(fpt_data), '8b')
      expect(memo.get(0)).to be_nil
    end
  end

  describe 'integration with the dBase IV fixture' do
    let(:table) { DBF::Table.new fixture('dbase_8b.dbf'), fixture('dbase_8b.dbt') }

    it 'reads memo content via the table' do
      record = table.each.find { |r| r && r.attributes.values.any? { |v| v.is_a?(String) && v.length > 0 } }
      expect(record).to_not be_nil
    end

    it 'closes the memo file' do
      table.close
      expect(table.closed?).to be true
    end
  end
end
