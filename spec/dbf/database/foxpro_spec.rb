require 'spec_helper'

RSpec.describe DBF::Database::Foxpro do
  let(:dbf_path) { fixture('foxprodb/FOXPRO-DB-TEST.DBC') }
  let(:db) { DBF::Database::Foxpro.new(dbf_path) }

  describe '#initialize' do
    describe 'when given a path to an existing dbc file' do
      it 'does not raise an error' do
        expect { DBF::Database::Foxpro.new dbf_path }.to_not raise_error
      end
    end

    describe 'when given a path to a non-existent dbf file' do
      it 'raises a DBF::FileNotFound error' do
        expect { DBF::Database::Foxpro.new 'x' }.to raise_error(DBF::FileNotFoundError, 'file not found: x')
      end
    end

    describe 'it loads the example db correctly' do
      it 'shows a correct list of tables' do
        expect(db.table_names.sort).to eq(%w[contacts calls setup types].sort)
      end
    end
  end

  describe '#table' do
    describe 'when accessing related tables' do
      let(:db) { DBF::Database::Foxpro.new(dbf_path) }

      it 'loads an existing related table' do
        expect(db.contacts.record_count).to eq 5
      end

      it 'supports a long table field name' do
        expect(db.contacts.record(1).spouses_interests).to eq 'Tennis, golf'
      end

      it 'loads an existing related table with wrong filename casing' do
        expect(db.calls.record_count).to eq 16
      end
    end
  end

  describe '#table_path' do
    it 'returns an absolute path' do
      expect(db.table_path('contacts')).to eq File.expand_path('spec/fixtures/foxprodb/contacts.dbf')
    end
  end

end
