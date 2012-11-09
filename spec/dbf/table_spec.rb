require "spec_helper"

describe DBF::Table do  
  specify 'foxpro versions' do
    DBF::Table::FOXPRO_VERSIONS.keys.sort.should == %w(30 31 f5 fb).sort
  end

  describe '#initialize' do
    it 'accepts a DBF filename' do
      expect { DBF::Table.new "#{DB_PATH}/dbase_83.dbf" }.to_not raise_error
    end

    it 'accepts a DBF and Memo filename' do
      expect { DBF::Table.new "#{DB_PATH}/dbase_83.dbf", "#{DB_PATH}/dbase_83.dbt" }.to_not raise_error
    end

    it 'accepts an io-like data object' do
      data = StringIO.new File.read("#{DB_PATH}/dbase_83.dbf")
      expect { DBF::Table.new data }.to_not raise_error
    end

    it 'accepts an io-like data and memo object' do
      data = StringIO.new File.read("#{DB_PATH}/dbase_83.dbf")
      memo = StringIO.new File.read("#{DB_PATH}/dbase_83.dbt")
      expect { DBF::Table.new data, memo }.to_not raise_error
    end
  end
  
  context "when closed" do
    it "closes the data and memo files" do
      table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      table.close
      table.should be_closed
    end
    
    it "closes the data" do
      table = DBF::Table.new "#{DB_PATH}/dbase_30.dbf"
      table.close
      table.should be_closed
    end
  end
  
  describe "#schema" do
    it "matches the test schema fixture" do
      table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      control_schema = File.read("#{DB_PATH}/dbase_83_schema.txt")
      table.schema.should == control_schema
    end
  end
  
  describe '#to_csv' do
    let(:table) { DBF::Table.new "#{DB_PATH}/dbase_83.dbf" }
    
    after do
      FileUtils.rm_f 'test.csv'
    end
    
    describe 'when no path param passed' do
      it 'writes to STDOUT' do
        begin
          $stdout = StringIO.new
          table.to_csv
          $stdout.string.should_not be_empty
        ensure
          $stdout = STDOUT
        end
      end
    end

    describe 'when path param passed' do
      it 'creates a custom csv file' do
        table.to_csv('test.csv')
        File.exists?('test.csv').should be_true
      end
    end
  end
  
  describe "#record" do
    it "return nil for deleted records" do
      table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      table.stub!(:deleted_record?).and_return(true)
      table.record(5).should be_nil
    end
  end
  
  describe "#current_record" do
    it "should return nil for deleted records" do
      table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      table.stub!(:deleted_record?).and_return(true)
      table.record(0).should be_nil
    end
  end
  
  describe "#find" do
    let(:table) { DBF::Table.new "#{DB_PATH}/dbase_83.dbf" }
    
    describe "with index" do
      it "returns the correct record" do
        table.find(5).should == table.record(5)
      end
    end
    
    describe 'with array of indexes' do      
      it "returns the correct records" do
        table.find([1, 5, 10]).should == [table.record(1), table.record(5), table.record(10)]
      end
    end
    
    describe "with :all" do
      it "accepts a block" do
        records = []
        table.find(:all, :weight => 0.0) do |record|
          records << record
        end
        records.should == table.find(:all, :weight => 0.0)
      end

      it "returns all records if options are empty" do
        table.find(:all).should == table.to_a
      end

      it "returns matching records when used with options" do
        table.find(:all, "WEIGHT" => 0.0).should == table.select {|r| r["weight"] == 0.0}
      end

      it "should AND multiple search terms" do
        table.find(:all, "ID" => 30, "IMAGE" => "graphics/00000001/TBC01.jpg").should == []
      end
      
      it "should match original column names" do
        table.find(:all, "WEIGHT" => 0.0).should_not be_empty
      end
      
      it "matches symbolized column names" do
        table.find(:all, :WEIGHT => 0.0).should_not be_empty
      end
      
      it "matches downcased column names" do
        table.find(:all, "weight" => 0.0).should_not be_empty
      end
      
      it "matches symbolized downcased column names" do
        table.find(:all, :weight => 0.0).should_not be_empty
      end
    end
    
    describe "with :first" do
      it "returns the first record if options are empty" do
        table.find(:first).should == table.record(0)
      end

      it "returns the first matching record when used with options" do
        table.find(:first, "CODE" => "C").should == table.record(5)
      end

      it "ANDs multiple search terms" do
        table.find(:first, "ID" => 30, "IMAGE" => "graphics/00000001/TBC01.jpg").should be_nil
      end
    end
  end

  describe "filename" do
    it 'is dbase_03.dbf' do
      table = DBF::Table.new "#{DB_PATH}/dbase_03.dbf"
      table.filename.should == "dbase_03.dbf"
    end
  end
  
  describe 'has_memo_file?' do
    describe 'without a memo file' do
      it 'is false' do
        table = DBF::Table.new "#{DB_PATH}/dbase_03.dbf"
        table.has_memo_file?.should be_false
      end
    end
    
    describe 'with a memo file' do
      it 'is true' do
        table = DBF::Table.new "#{DB_PATH}/dbase_30.dbf" 
        table.has_memo_file?.should be_true
      end
    end
  end

  describe 'columns' do
    let(:table) { DBF::Table.new "#{DB_PATH}/dbase_03.dbf" }

    it 'should have correct size' do
      table.columns.size.should == 31
    end

    it 'should have correct names' do
      table.columns.first.name.should == 'Point_ID'
      table.columns[29].name.should == 'Easting'
    end
  end
end

