require "spec_helper"

describe DBF::FoxproDatabase do
  let(:dbf_path) { fixture_path('foxprodb/FOXPRO-DB-TEST.DBC') }

  describe '#initialize' do
    describe 'when given a path to an existing dbc file' do
      it 'does not raise an error' do
        expect { DBF::FoxproDatabase.new dbf_path }.to_not raise_error
      end
    end

    describe 'when given a path to a non-existent dbf file' do
      it 'raises a DBF::FileNotFound error' do
        expect { DBF::FoxproDatabase.new "x" }.to raise_error(DBF::FileNotFoundError, 'file not found: x')
      end
    end

    describe 'it loads the example db correctly' do
      it 'shows a correct list of tables' do
        expect(DBF::FoxproDatabase.new(dbf_path).tables.sort).to eq(%w(contacts calls setup types).sort)
      end
    end

  end

  describe '#table' do
    it 'loads an existing related table' do
      expect(DBF::FoxproDatabase.new(dbf_path).contacts.record_count).to eq 5
    end

    it 'supports a long table field name' do
      expect(DBF::FoxproDatabase.new(dbf_path).contacts.record(1).spouses_interests).to eq "Tennis, golf"
    end

    it 'loads an existing related table with wrong filename casing' do
      expect(DBF::FoxproDatabase.new(dbf_path).calls.record_count).to eq 16
    end
  end

end