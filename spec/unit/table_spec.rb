require File.dirname(__FILE__) + "/../spec_helper"

describe DBF::Table, "when initialized" do
  
  before(:all) do
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

describe DBF::Table, "when the in_memory flag is true" do
  
  before(:each) do
    @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
  end
  
  it "should build the records array from disk only on the first request" do
    @table.expects(:get_all_records_from_file).at_most_once.returns([])
    3.times { @table.records }
  end
  
  it "should read from the records array when using the record() method" do
    @table.expects(:get_all_records_from_file).at_most_once.returns([])
    @table.expects(:get_record_from_file).never
    @table.expects(:records).times(2).returns([])
    @table.record(1)
    @table.record(10)
  end
  
end

describe DBF::Table, "when the in_memory flag is false" do
  
  it "should read the records from disk on every request" do
    table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf", :in_memory => false
    table.expects(:get_all_records_from_file).times(3).returns([])
    3.times { table.records }
  end
end

describe DBF::Table, "schema" do
  
  it "should match test schema " do
    table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
    control_schema = File.read(File.dirname(__FILE__) + '/../fixtures/dbase_83_schema.txt')
    
    table.schema.should == control_schema
  end
  
end

describe DBF::Table, "find(index)" do
  
  before(:all) do
    @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
  end
  
  it "should return the correct record" do
    @table.find(5).should == @table.record(5)
  end
  
end

describe DBF::Table, "find(:all)" do
  
  before(:all) do
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

describe DBF::Table, "find(:first)" do
  
  before(:all) do
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

describe DBF::Table do
  
  before(:each) do
    @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
  end
  
  it "should reload all data when sent #reload!" do
    @table.records
    @table.instance_eval("@records").should be_kind_of(Array)
    @table.reload!
    @table.instance_eval("@records").should be_nil
  end
  
  it "should return a DBF::Field object when sent #column with a valid column_name given as a string or symbol" do
    @table.column("IMAGE").should be_kind_of(DBF::Column)
    @table.column(:IMAGE).should be_kind_of(DBF::Column)
  end
  
  it "should return nil when sent #column with an invalid column_name given as a string or symbol" do
    @table.column("NOTANIMAGE").should be_nil
    @table.column(:NOTANIMAGE).should be_nil
  end
  
  it "should return a text description of the database type when sent #version_description" do
    @table.version_description.should == "dBase III with memo file"
  end

end

