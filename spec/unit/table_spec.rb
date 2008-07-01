require File.dirname(__FILE__) + "/../spec_helper"

describe DBF::Table do
  
  context "when initialized" do
    before do
      @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
    end

    it "should load the data file" do
      @table.data.should be_kind_of(File)
    end

    it "should locate load the memo file" do
      @table.has_memo_file?.should be_true
      @table.instance_eval("@memo").should be_kind_of(File)
    end

    it "should determine the memo file format" do
      @table.memo_file_format.should == :dbt
    end

    it "should determine the correct memo block size" do
      @table.memo_block_size.should == 512
    end

    it "should default to loading all records into memory" do
      @table.options[:in_memory].should be_true
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

    it "should set the in_memory option" do
      table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf", :in_memory => false
      table.options[:in_memory].should be_false
    end
  end
  
  context "when the in_memory flag is true" do
    before do
      @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
    end

    it "should read from the records array when using the record() method" do
      @table.should_receive(:get_record_from_file).never
      @table.should_receive(:records).exactly(2).times.and_return([])
      @table.record(1)
      @table.record(10)
    end
  end
  
  describe "#find" do
    describe "with index" do
      it "should return the correct record" do
        table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
        table.find(5).should == table.record(5)
      end
    end

    describe "with :all" do
      before do
        @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      end

      it "should return all records if options are empty" do
        @table.find(:all).should == @table.records
      end

      it "should return matching records when used with options" do
        @table.find(:all, "WEIGHT" => 0.0).should == @table.records.select {|r| r.attributes["WEIGHT"] == 0.0}
      end

      it "with multiple options should search for all search terms as if using AND" do
        @table.find(:all, "ID" => 30, "IMAGE" => "graphics/00000001/TBC01.jpg").should == []
      end
    end

    describe "with :first" do
      before do
        @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      end

      it "should return the first record if options are empty" do
        @table.find(:first).should == @table.records.first
      end

      it "should return the first matching record when used with options" do
        @table.find(:first, "CODE" => "C").should == @table.record(5)
      end

      it "with multiple options should search for all search terms as if using AND" do
        @table.find(:first, "ID" => 30, "IMAGE" => "graphics/00000001/TBC01.jpg").should be_nil
      end
    end
  end
  
  describe "#reload" do
    it "should reload all data" do
      table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      table.records
      table.instance_eval("@records").should be_kind_of(Array)
      table.reload!
      table.instance_eval("@records").should be_nil
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
    it 'should replace the extname' do
      table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      table.send(:replace_extname, "dbase_83.dbf", 'fpt').should == 'dbase_83.fpt'
    end
  end
  
  describe '#each' do
    it 'should enumerate all records' do
      table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      records = []
      table.each do |record|
        records << record
      end
      
      records.each_with_index do |record, index|
        record.attributes.should == table.records[index].attributes
      end
    end
    # 
    # it 'should support to_a' do
    #   table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
    #   table.to_a.should == table.records
    # end
  end

end

