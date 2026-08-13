# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DBF::RecordIterator do
  let(:table) { DBF::Table.new fixture('dbase_83.dbf') }
  let(:data) { File.open(fixture('dbase_83.dbf'), 'rb') }

  after { data.close }

  def iterator(chunk_size:)
    described_class.new(
      data, table.record_context, table.header_length,
      table.record_length, table.record_count, chunk_size: chunk_size
    )
  end

  def attributes_with(chunk_size:)
    iterator(chunk_size: chunk_size).each.map { |record| record&.attributes }
  end

  describe 'chunked reading' do
    it 'yields identical records whether the chunk holds one record or the whole file' do
      whole_file = attributes_with(chunk_size: table.record_length * table.record_count)
      one_at_a_time = attributes_with(chunk_size: 1)

      expect(whole_file.size).to eq table.record_count
      expect(one_at_a_time).to eq whole_file
    end

    it 'yields identical records across an uneven chunk boundary' do
      uneven = attributes_with(chunk_size: (table.record_length * 7) + 3)
      expect(uneven).to eq attributes_with(chunk_size: table.record_length * table.record_count)
    end

    it 'never requests more than one chunk of whole records per read' do
      max_chunk_bytes = table.record_length * 7
      allow(data).to receive(:read).and_wrap_original do |original, length|
        expect(length).to be <= max_chunk_bytes
        original.call(length)
      end
      iterator(chunk_size: max_chunk_bytes).each { |_record| } # rubocop:disable Lint/EmptyBlock
    end

    it 'reads at least one whole record when the chunk size is smaller than a record' do
      records = attributes_with(chunk_size: 1)
      expect(records.size).to eq table.record_count
    end
  end
end
