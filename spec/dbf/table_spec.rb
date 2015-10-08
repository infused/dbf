require 'spec_helper'

describe DBF::Table do
  let(:dbf_path) { fixture_path('dbase_83.dbf') }
  let(:memo_path) { fixture_path('dbase_83.dbt') }
  let(:table) { DBF::Table.new dbf_path }

  specify 'foxpro versions' do
    expect(DBF::Table::FOXPRO_VERSIONS.keys.sort).to eq %w(30 31 f5 fb).sort
  end

  describe '#initialize' do
    describe 'when given a path to an existing dbf file' do
      it 'does not raise an error' do
        expect { DBF::Table.new dbf_path }.to_not raise_error
      end
    end

    describe 'when given a path to a non-existent dbf file' do
      it 'raises a DBF::FileNotFound error' do
        expect { DBF::Table.new 'x' }.to raise_error(DBF::FileNotFoundError, 'file not found: x')
      end
    end

    describe 'when given paths to existing dbf and memo files' do
      it 'does not raise an error' do
        expect { DBF::Table.new dbf_path, memo_path }.to_not raise_error
      end
    end

    it 'accepts an io-like data object' do
      data = StringIO.new File.read(dbf_path)
      expect { DBF::Table.new data }.to_not raise_error
    end

    it 'accepts an io-like data and memo object' do
      data = StringIO.new File.read(dbf_path)
      memo = StringIO.new File.read(memo_path)
      expect { DBF::Table.new data, memo }.to_not raise_error
    end
  end

  context '#close' do
    it 'closes the io' do
      table.close
      expect { table.record(1) }.to raise_error(IOError)
    end
  end

  describe '#schema' do
    it 'matches the test schema fixture' do
      control_schema = File.read(fixture_path('dbase_83_schema.txt'))
      expect(table.schema).to eq control_schema
    end
  end

  describe '#json_schema' do
    it 'is valid JSON' do
      expect { JSON.parse(table.json_schema) }.to_not raise_error
    end

    it 'matches the test fixture' do
      data = JSON.parse(table.json_schema)
      expect(data).to eq [
        {'name' => 'ID', 'type' => 'N', 'length' => 19, 'decimal' => 0},
        {'name' => 'CATCOUNT', 'type' => 'N', 'length' => 19, 'decimal' => 0},
        {'name' => 'AGRPCOUNT', 'type' => 'N', 'length' => 19, 'decimal' => 0},
        {'name' => 'PGRPCOUNT', 'type' => 'N', 'length' => 19, 'decimal' => 0},
        {'name' => 'ORDER', 'type' => 'N', 'length' => 19, 'decimal' => 0},
        {'name' => 'CODE', 'type' => 'C', 'length' => 50, 'decimal' => 0},
        {'name' => 'NAME', 'type' => 'C', 'length' => 100, 'decimal' => 0},
        {'name' => 'THUMBNAIL', 'type' => 'C', 'length' => 254, 'decimal' => 0},
        {'name' => 'IMAGE', 'type' => 'C', 'length' => 254, 'decimal' => 0},
        {'name' => 'PRICE', 'type' => 'N', 'length' => 13, 'decimal' => 2},
        {'name' => 'COST', 'type' => 'N', 'length' => 13, 'decimal' => 2},
        {'name' => 'DESC', 'type' => 'M', 'length' => 10, 'decimal' => 0},
        {'name' => 'WEIGHT', 'type' => 'N', 'length' => 13, 'decimal' => 2},
        {'name' => 'TAXABLE', 'type' => 'L', 'length' => 1, 'decimal' => 0},
        {'name' => 'ACTIVE', 'type' => 'L', 'length' => 1, 'decimal' => 0}
      ]
    end
  end

  describe '#to_csv' do
    after do
      FileUtils.rm_f 'test.csv'
    end

    describe 'when no path param passed' do
      it 'writes to STDOUT' do
        begin
          $stdout = StringIO.new
          table.to_csv
          expect($stdout.string).not_to be_empty
        ensure
          $stdout = STDOUT
        end
      end
    end

    describe 'when path param passed' do
      it 'creates a custom csv file' do
        table.to_csv('test.csv')
        expect(File.exist?('test.csv')).to be_truthy
      end
    end
  end

  describe '#record' do
    it 'return nil for deleted records' do
      allow(table).to receive(:deleted_record?).and_return(true)
      expect(table.record(5)).to be_nil
    end
  end

  describe '#current_record' do
    it 'should return nil for deleted records' do
      allow(table).to receive(:deleted_record?).and_return(true)
      expect(table.record(0)).to be_nil
    end
  end

  describe '#find' do
    describe 'with index' do
      it 'returns the correct record' do
        expect(table.find(5)).to eq table.record(5)
      end
    end

    describe 'with array of indexes' do
      it 'returns the correct records' do
        expect(table.find([1, 5, 10])).to eq [table.record(1), table.record(5), table.record(10)]
      end
    end

    describe 'with :all' do
      it 'accepts a block' do
        records = []
        table.find(:all, :weight => 0.0) do |record|
          records << record
        end
        expect(records).to eq table.find(:all, :weight => 0.0)
      end

      it 'returns all records if options are empty' do
        expect(table.find(:all)).to eq table.to_a
      end

      it 'returns matching records when used with options' do
        expect(table.find(:all, 'WEIGHT' => 0.0)).to eq table.select {|r| r['weight'] == 0.0}
      end

      it 'should AND multiple search terms' do
        expect(table.find(:all, 'ID' => 30, :IMAGE => 'graphics/00000001/TBC01.jpg')).to be_empty
      end

      it 'should match original column names' do
        expect(table.find(:all, 'WEIGHT' => 0.0)).not_to be_empty
      end

      it 'matches symbolized column names' do
        expect(table.find(:all, :WEIGHT => 0.0)).not_to be_empty
      end

      it 'matches downcased column names' do
        expect(table.find(:all, 'weight' => 0.0)).not_to be_empty
      end

      it 'matches symbolized downcased column names' do
        expect(table.find(:all, :weight => 0.0)).not_to be_empty
      end
    end

    describe 'with :first' do
      it 'returns the first record if options are empty' do
        expect(table.find(:first)).to eq table.record(0)
      end

      it 'returns the first matching record when used with options' do
        expect(table.find(:first, 'CODE' => 'C')).to eq table.record(5)
      end

      it 'ANDs multiple search terms' do
        expect(table.find(:first, 'ID' => 30, 'IMAGE' => 'graphics/00000001/TBC01.jpg')).to be_nil
      end
    end
  end

  describe '#filename' do
    it 'returns the filename as a string' do
      expect(table.filename).to eq 'dbase_83.dbf'
    end
  end

  describe '#has_memo_file?' do
    describe 'without a memo file' do
      it 'is false' do
        table = DBF::Table.new fixture_path('dbase_03.dbf')
        expect(table.has_memo_file?).to be_falsey
      end
    end

    describe 'with a memo file' do
      it 'is true' do
        expect(table.has_memo_file?).to be_truthy
      end
    end
  end

  describe '#columns' do
    it 'is an array of Columns' do
      expect(table.columns).to be_an(Array)
      expect(table.columns).to_not be_empty
      expect(table.columns.all? {|c| c.class == DBF::Column::Dbase}).to be_truthy
    end
  end

  describe '#column_names' do
    it 'is an array of all column names' do
      correct_column_names = %w(ID CATCOUNT AGRPCOUNT PGRPCOUNT ORDER CODE NAME THUMBNAIL IMAGE PRICE COST DESC WEIGHT TAXABLE ACTIVE)
      expect(table.column_names).to eq correct_column_names
    end
  end

end
