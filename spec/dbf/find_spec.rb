# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DBF::Find do
  let(:table) { DBF::Table.new fixture('dbase_83.dbf') }

  describe '#find' do
    it 'returns the record at a given integer index' do
      expect(table.find(0)).to eq table.record(0)
    end

    it 'maps an Array of indexes to records preserving order' do
      expect(table.find([2, 0, 1])).to eq [table.record(2), table.record(0), table.record(1)]
    end

    it 'returns nil for an unknown command symbol' do
      expect(table.find(:unknown)).to be_nil
    end

    describe ':first' do
      it 'returns nil when nothing matches' do
        expect(table.find(:first, 'CODE' => '__no_such_code__')).to be_nil
      end

      it 'returns the first record when options is empty' do
        expect(table.find(:first)).to eq table.record(0)
      end
    end

    describe ':all' do
      it 'returns [] when nothing matches' do
        expect(table.find(:all, 'CODE' => '__no_such_code__')).to eq []
      end

      it 'yields each match to the block and returns the same matches' do
        yielded = []
        result = table.find(:all, weight: 0.0) { |r| yielded << r }
        expect(yielded).to_not be_empty
        expect(result).to eq yielded
      end

      it 'AND-combines multiple search keys' do
        only_code_c = table.find(:all, 'CODE' => 'C').size
        narrowed = table.find(:all, 'CODE' => 'C', 'ID' => -1).size
        expect(narrowed).to eq 0
        expect(only_code_c).to be > 0
      end
    end
  end
end
