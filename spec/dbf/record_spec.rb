require 'spec_helper'

RSpec.describe DBF::Record do
  describe '#to_a' do
    let(:table) { DBF::Table.new fixture('dbase_83.dbf') }
    let(:record0) { YAML.load_file(fixture('dbase_83_record_0.yml')) }
    let(:record9) { YAML.load_file(fixture('dbase_83_record_9.yml')) }

    it 'returns an ordered array of attribute values' do
      record = table.record(0)
      expect(record.to_a).to eq record0

      record = table.record(9)
      expect(record.to_a).to eq record9
    end

    describe 'with missing memo file' do
      describe 'when opening a path' do
        let(:table) { DBF::Table.new fixture('dbase_83_missing_memo.dbf') }
        let(:record0) { YAML.load_file(fixture('dbase_83_missing_memo_record_0.yml')) }

        it 'returns nil values for memo fields' do
          record = table.record(0)
          expect(record.to_a).to eq record0
        end
      end
    end

    describe 'when opening StringIO' do
      let(:data) { StringIO.new(File.read(fixture('dbase_83_missing_memo.dbf'))) }
      let(:table) { DBF::Table.new(data) }
      let(:record0) { YAML.load_file(fixture('dbase_83_missing_memo_record_0.yml')) }

      it 'returns nil values for memo fields' do
        record = table.record(0)
        expect(record.to_a).to eq record0
      end
    end
  end

  describe '#==' do
    let(:table) { DBF::Table.new fixture('dbase_8b.dbf') }
    let(:record) { table.record(9) }

    describe 'when other does not have attributes' do
      it 'returns false' do
        expect((record == instance_double('DBF::Record'))).to be_falsey
      end
    end

    describe 'if other attributes match' do
      let(:attributes) { {x: 1, y: 2} }
      let(:other) { instance_double('DBF::Record', attributes:) }

      before do
        allow(record).to receive(:attributes).and_return(attributes)
      end

      it 'returns true' do
        expect(record == other).to be_truthy
      end
    end

  end

  describe 'column accessors' do
    let(:table) { DBF::Table.new fixture('dbase_8b.dbf') }
    let(:record) { table.find(0) }

    %w[character numerical date logical float memo].each do |column_name|
      it "defines accessor method for '#{column_name}' column" do
        expect(record).to respond_to(column_name.to_sym)
      end

    end
  end

  describe 'column data for table' do
    describe 'using specified in dbf encoding' do
      let(:table) { DBF::Table.new fixture('cp1251.dbf') }
      let(:record) { table.find(0) }

      it 'encodes to default system encoding' do
        expect(record.name.encoding).to eq Encoding.default_external

        # russian a
        expect(record.name.encode('UTF-8').unpack1('H4')).to eq 'd0b0'
      end
    end

    describe 'overriding specified in dbf encoding' do
      let(:table) { DBF::Table.new fixture('cp1251.dbf'), nil, 'cp866' }
      let(:record) { table.find(0) }

      it 'transcodes from manually specified encoding to default system encoding' do
        expect(record.name.encoding).to eq Encoding.default_external

        # russian а encoded in cp1251 and read as if it was encoded in cp866
        expect(record.name.encode('UTF-8').unpack1('H4')).to eq 'd180'
      end
    end
  end

  describe '#attributes' do
    let(:table) { DBF::Table.new fixture('dbase_8b.dbf') }
    let(:record) { table.find(0) }

    it 'is a hash of attribute name/value pairs' do
      expect(record.attributes).to be_a(Hash)
      expect(record.attributes['CHARACTER']).to eq 'One'
    end

    it 'has only original field names as keys' do
      original_field_names = %w[CHARACTER DATE FLOAT LOGICAL MEMO NUMERICAL]
      expect(record.attributes.keys.sort).to eq original_field_names
    end
  end
end
