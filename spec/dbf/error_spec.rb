# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DBF::Error do
  it 'is the ancestor of every DBF error class' do
    expect(DBF::FileNotFoundError).to be < DBF::Error
    expect(DBF::NoColumnsDefined).to be < DBF::Error
    expect(DBF::Column::LengthError).to be < DBF::Error
    expect(DBF::Column::InvalidNameError).to be < DBF::Error
  end

  it 'allows rescuing the library as a unit' do
    expect { DBF::Table.new 'missing.dbf' }.to raise_error(DBF::Error)
  end

  describe 'DBF::Column::NameError (deprecated)' do
    around do |example|
      deprecated = Warning[:deprecated]
      Warning[:deprecated] = false
      example.run
      Warning[:deprecated] = deprecated
    end

    it 'remains a rescuable alias of InvalidNameError' do
      expect(DBF::Column::NameError).to be DBF::Column::InvalidNameError
    end
  end
end
