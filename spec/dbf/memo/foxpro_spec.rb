# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DBF::Memo::Foxpro do
  describe '#build_memo' do
    it 'returns nil on IO error' do
      data = StringIO.new('')
      memo = DBF::Memo::Foxpro.new(data, '30')
      allow(data).to receive(:seek).and_raise(IOError)
      expect(memo.get(1)).to be_nil
    end

    it 'returns nil when the start block is past the end of the file' do
      header = +("\x00" * 512)
      header[6, 2] = [64].pack('n')
      memo = DBF::Memo::Foxpro.new(StringIO.new(header), '30')
      expect(memo.get(8)).to be_nil
    end

    it 'returns nil when the memo file is shorter than the FPT header' do
      memo = DBF::Memo::Foxpro.new(StringIO.new('xy'), '30')
      expect(memo.get(1)).to be_nil
    end

    it 'returns nil when the block header is truncated' do
      header = +("\x00" * 512)
      header[6, 2] = [64].pack('n')
      truncated_block_header = [1].pack('N') # memo_type only, no memo_size
      memo = DBF::Memo::Foxpro.new(StringIO.new(header + truncated_block_header), '30')
      expect(memo.get(8)).to be_nil
    end

    it 'does not swallow unrelated programmer errors' do
      data = StringIO.new('')
      memo = DBF::Memo::Foxpro.new(data, '30')
      allow(data).to receive(:seek).and_raise(NoMethodError)
      expect { memo.get(1) }.to raise_error(NoMethodError)
    end
  end

  describe 'multi-block memo' do
    let(:block_size) { 64 }
    let(:content_size) { block_size - 8 }
    let(:memo_text) { 'x' * (content_size + 10) }

    let(:fpt_data) do
      # Build FPT header (512 bytes): block size at offset 6 (big-endian 16-bit)
      header = "\x00" * 512
      header[6, 2] = [block_size].pack('n')

      # Build memo block at block 8 (offset 512 = 8 * 64)
      # Block header: type (4 bytes big-endian) + size (4 bytes big-endian)
      block_header = [1, memo_text.bytesize].pack('NN')
      first_block_content = memo_text[0, content_size]
      remaining = memo_text[content_size..]

      header + block_header + first_block_content + remaining
    end

    it 'reads memo content spanning multiple blocks' do
      data = StringIO.new(fpt_data)
      memo = DBF::Memo::Foxpro.new(data, '30')
      result = memo.get(8)
      expect(result).to eq memo_text
    end
  end
end
