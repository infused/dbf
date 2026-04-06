# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DBF::Record do
  describe '#to_a' do
    let(:table) { DBF::Table.new fixture('dbase_83.dbf') }

    it 'returns an ordered array of attribute values' do
      record = table.record(0)
      expect(record.to_a).to eq YAML.load_file(fixture('dbase_83_record_0.yml'))

      record = table.record(9)
      expect(record.to_a).to eq YAML.load_file(fixture('dbase_83_record_9.yml'))
    end

    describe 'with missing memo file' do
      describe 'when opening a path' do
        let(:table) { DBF::Table.new fixture('dbase_83_missing_memo.dbf') }

        it 'returns nil values for memo fields' do
          record = table.record(0)
          expect(record.to_a).to eq YAML.load_file(fixture('dbase_83_missing_memo_record_0.yml'))
        end
      end
    end

    describe 'when opening StringIO' do
      let(:data) { StringIO.new(File.read(fixture('dbase_83_missing_memo.dbf'))) }
      let(:table) { DBF::Table.new(data) }

      it 'returns nil values for memo fields' do
        record = table.record(0)
        expect(record.to_a).to eq YAML.load_file(fixture('dbase_83_missing_memo_record_0.yml'))
      end
    end
  end

  describe '#==' do
    let(:table) { DBF::Table.new fixture('dbase_8b.dbf') }
    let(:record) { table.record(9) }

    describe 'when other does not have attributes' do
      it 'returns false' do
        expect(record == Object.new).to be_falsey
      end
    end

    describe 'if other attributes match' do
      let(:attributes) { {x: 1, y: 2} }
      let(:other) { instance_double(DBF::Record, attributes: attributes) }

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

  describe '#[]' do
    let(:table) { DBF::Table.new fixture('dbase_8b.dbf') }

    describe 'with column_offsets and no prior to_a' do
      it 'returns value by column name' do
        record = table.record(0)
        expect(record['CHARACTER']).to eq 'One'
      end

      it 'returns nil for unknown column name' do
        record = table.record(0)
        expect(record['NONEXISTENT']).to be_nil
      end
    end

    describe 'after to_a with original column name' do
      it 'returns value by original column name' do
        record = table.record(0)
        record.to_a
        expect(record['CHARACTER']).to eq 'One'
      end
    end

    describe 'after to_a with underscored column name' do
      it 'returns value by underscored name' do
        record = table.record(0)
        record.to_a
        expect(record['character']).to eq 'One'
      end
    end
  end

  describe 'method_missing' do
    let(:table) { DBF::Table.new fixture('dbase_8b.dbf') }

    it 'returns attribute value after to_a has been called' do
      record = table.record(0)
      record.to_a
      expect(record.character).to eq 'One'
    end

    it 'raises NoMethodError for nonexistent column' do
      record = table.record(0)
      expect { record.nonexistent_column }.to raise_error(NoMethodError)
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
