require File.expand_path(File.join(File.dirname(__FILE__), "../spec_helper"))

describe DBF::Table do
  context "when initialized" do
    before do
      @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
    end

    it "should load the data file" do
      @table.data.should be_kind_of(File)
    end

    it "should load the memo file" do
      @table.has_memo_file?.should be_true
      @table.instance_eval("@memo").should be_kind_of(File)
    end

    it "should determine the memo file format" do
      @table.memo_file_format.should == :dbt
    end

    it "should determine the correct memo block size" do
      @table.memo_block_size.should == 512
    end

    it "should determine the number of columns in each record" do
      @table.columns.size.should == 15
    end

    it "should determine the number of records in the database" do
      @table.record_count.should == 67
    end

    it "should determine the database version" do
      @table.version.should == "83"
    end
  end
  
  context "when closed" do
    before do
      @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
    end
    
    it "should close the data file" do
      @table.close
      lambda { @table.record(1) }.should raise_error(IOError)
    end
  end
  
  describe "#column" do
    it "should accept a string or symbol as input" do
      table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      table.column(:IMAGE).should be_kind_of(DBF::Column)
      table.column("IMAGE").should be_kind_of(DBF::Column)
    end
    
    it "should return a DBF::Field object when the column_name exists" do
      table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      table.column(:IMAGE).should be_kind_of(DBF::Column)
    end
  
    it "should return nil when the column_name does not exist" do
      table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      table.column(:NOTANIMAGE).should be_nil
    end
  end
  
  describe "#schema" do
    it "should match the test schema fixture" do
      table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      control_schema = File.read(File.dirname(__FILE__) + '/../fixtures/dbase_83_schema.txt')

      table.schema.should == control_schema
    end
  end
  
  describe "#version_description" do
    it "should return a text description of the database type" do
      table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      table.version_description.should == "dBase III with memo file"
    end
  end
  
  describe '#replace_extname' do
    it "should change the file extension" do
      table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      table.send(:replace_extname, 'dbase_83.dbf', 'fpt').should == 'dbase_83.fpt'
    end
  end
  
  describe '#to_a' do
    before do
      @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      
      @records = []
      @table.each {|record| @records << record}
    end
    
    it 'should return an array of records' do
      @table.to_a.should == @records
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
    
    it 'should create custom csv file' do
      @table.to_csv('test.csv')
      File.exists?('test.csv').should be_true
    end
  end
  
  describe "#record" do
    before do
      @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      
      @records = []
      @table.each {|record| @records << record}
    end
    
    it "should nullify deleted records" do
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
    
    it 'should return a DBF::Record' do
      @table.record(0).should be_kind_of(DBF::Record)
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
        
        @records = []
        @table.each {|record| @records << record}
      end
      
      it "should accept a block" do
        records = []
        @table.find(:all, :weight => 0.0) do |record|
          records << record
        end
        records.should == @table.find(:all, :weight => 0.0)
      end

      it "should return all records if options are empty" do
        @table.find(:all).should == @records
      end

      it "should return matching records when used with options" do
        @table.find(:all, "WEIGHT" => 0.0).should == @records.select {|r| r.attributes["weight"] == 0.0}
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
        
        @records = []
        @table.each {|record| @records << record}
      end

      it "should return the first record if options are empty" do
        @table.find(:first).should == @records.first
      end

      it "should return the first matching record when used with options" do
        @table.find(:first, "CODE" => "C").should == @records[5]
      end

      it "should AND multiple search terms" do
        @table.find(:first, "ID" => 30, "IMAGE" => "graphics/00000001/TBC01.jpg").should be_nil
      end
    end
  end

end

