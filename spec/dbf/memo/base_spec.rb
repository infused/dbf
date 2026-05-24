# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DBF::Memo::Base do
  describe '#closed?' do
    let(:data) { File.open(fixture('dbase_83.dbt'), 'rb') }
    let(:memo) { DBF::Memo::Dbase3.new(data, '83') }

    it 'returns false when open' do
      expect(memo.closed?).to be false
    end

    it 'returns true after closing' do
      memo.close
      expect(memo.closed?).to be true
    end
  end
end
