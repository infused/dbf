require "spec_helper"

describe DBF::Table do  
  # specify do
  #   DBF::Table::FOXPRO_VERSIONS.should == %w(30 31 f5 fb)
  # end
  
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
      control_schema = File.read(File.dirname(__FILE__) + '/../fixtures/dbase_83_schema.txt')

      table.schema.should == control_schema
    end
  end
  
  describe '#to_csv' do
    before do
      @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
    end
    
    after do
      FileUtils.rm_f 'dbase_83.csv'
      FileUtils.rm_f 'test.csv'
    end
    
    it 'should create default dump.csv' do
      @table.to_csv
      File.exists?('dbase_83.csv').should be_true
    end

    describe 'when path param passed' do
      it 'should create custom csv file' do
        @table.to_csv('test.csv')
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
        @table.find(:first).should == @table.first
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
end

