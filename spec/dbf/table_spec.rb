require "spec_helper"

describe DBF::Table do  
  specify 'foxpro versions' do
    DBF::Table::FOXPRO_VERSIONS.keys.sort.should == %w(30 31 f5 fb).sort
  end

  describe '#initialize' do
    it 'should accept a DBF filename' do
      expect { DBF::Table.new "#{DB_PATH}/dbase_83.dbf" }.to_not raise_error
    end

    it 'should accept a DBF and Memo filename' do
      expect { DBF::Table.new "#{DB_PATH}/dbase_83.dbf", "#{DB_PATH}/dbase_83.dbt" }.to_not raise_error
    end

    it 'should accept an io-like data object' do
      data = StringIO.new File.read("#{DB_PATH}/dbase_83.dbf")
      expect { DBF::Table.new data }.to_not raise_error
    end

    it 'should accept an io-like data and memo object' do
      data = StringIO.new File.read("#{DB_PATH}/dbase_83.dbf")
      memo = StringIO.new File.read("#{DB_PATH}/dbase_83.dbt")
      expect { DBF::Table.new data, memo }.to_not raise_error
    end
  end
  
  context "when closed" do
    before do
      @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      @table.close
    end
    
    it "should close the data file" do
      @table.instance_eval { @data }.should be_closed
    end
    
    it "should close the memo file" do
      @table.instance_eval { @memo }.instance_eval { @data }.should be_closed
    end
  end
  
  describe "#schema" do
    it "should match the test schema fixture" do
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
      it 'should dump to STDOUT' do
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
      it 'should create custom csv file' do
        table.to_csv('test.csv')
        File.exists?('test.csv').should be_true
      end
    end
  end
  
  describe "#record" do
    before do
      @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
    end
    
    it "return nil for deleted records" do
      @table.stub!(:deleted_record?).and_return(true)
      @table.record(5).should be_nil
    end
  end
  
  describe "#current_record" do
    before do
      @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
    end
    
    it "should return nil for deleted records" do
      @table.stub!(:deleted_record?).and_return(true)
      @table.record(0).should be_nil
    end
  end
  
  describe "#find" do
    describe "with index" do
      before do
        @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      end
      
      it "should return the correct record" do
        @table.find(5).should == @table.record(5)
      end
    end
    
    describe 'with array of indexes' do
      before do
        @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      end
      
      it "should return the correct records" do
        @table.find([1, 5, 10]).should == [@table.record(1), @table.record(5), @table.record(10)]
      end
    end
    
    describe "with :all" do
      before do
        @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      end
      
      it "should accept a block" do
        records = []
        @table.find(:all, :weight => 0.0) do |record|
          records << record
        end
        records.should == @table.find(:all, :weight => 0.0)
      end

      it "should return all records if options are empty" do
        @table.find(:all).should == @table.to_a
      end

      it "should return matching records when used with options" do
        @table.find(:all, "WEIGHT" => 0.0).should == @table.select {|r| r.attributes["weight"] == 0.0}
      end

      it "should AND multiple search terms" do
        @table.find(:all, "ID" => 30, "IMAGE" => "graphics/00000001/TBC01.jpg").should == []
      end
      
      it "should match original column names" do
        @table.find(:all, "WEIGHT" => 0.0).should_not be_empty
      end
      
      it "should match symbolized column names" do
        @table.find(:all, :WEIGHT => 0.0).should_not be_empty
      end
      
      it "should match downcased column names" do
        @table.find(:all, "weight" => 0.0).should_not be_empty
      end
      
      it "should match symbolized downcased column names" do
        @table.find(:all, :weight => 0.0).should_not be_empty
      end
    end
    
    describe "with :first" do
      before do
        @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      end

      it "should return the first record if options are empty" do
        @table.find(:first).should == @table.record(0)
      end

      it "should return the first matching record when used with options" do
        @table.find(:first, "CODE" => "C").should == @table.record(5)
      end

      it "should AND multiple search terms" do
        @table.find(:first, "ID" => 30, "IMAGE" => "graphics/00000001/TBC01.jpg").should be_nil
      end
    end
  end

  describe "filename" do
    before do
      @table = DBF::Table.new "#{DB_PATH}/dbase_03.dbf"
    end
    
    it 'should be dbase_03.dbf' do
      @table.filename.should == "dbase_03.dbf"
    end
  end
  
  describe 'has_memo_file?' do
    describe 'without a memo file' do
      let(:table) { DBF::Table.new "#{DB_PATH}/dbase_03.dbf" }
      specify { table.has_memo_file?.should be_false }
    end
    
    describe 'with a memo file' do
      let(:table) { DBF::Table.new "#{DB_PATH}/dbase_30.dbf" }
      specify { table.has_memo_file?.should be_true }
    end
  end

  describe 'columns' do
    before do
      @table = DBF::Table.new "#{DB_PATH}/dbase_03.dbf"
    end

    it 'should have correct size' do
      @table.columns.size.should == 31
    end

    it 'should have correct names' do
      @table.columns.first.name.should == 'Point_ID'
      @table.columns[29].name.should == 'Easting'
    end
  end
end

