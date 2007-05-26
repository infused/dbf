require File.dirname(__FILE__) + "/spec_helper"

describe DBF::Reader, "when initialized" do
  
  before(:all) do
    @reader = DBF::Reader.new File.dirname(__FILE__) + '/../test/databases/dbase_iii_memo.dbf'
  end
  
  it "should load the data file" do
    @reader.instance_eval("@data_file").should be_kind_of(File)
  end
  
  it "should locate load the memo file" do
    @reader.has_memo_file?.should be_true
    @reader.instance_eval("@memo_file").should be_kind_of(File)
  end
  
  it "should determine the memo file format" do
    @reader.memo_file_format.should == :dbt
  end
  
  it "should determine the memo block size" do
    @reader.memo_block_size.should == 512
  end
  
  it "should default to loading all records into memory" do
    @reader.in_memory?.should be_true
  end
  
  it "should determine the number of fields in each record" do
    @reader.fields.size.should == 15
  end
  
  it "should determine the number of records in the database" do
    @reader.record_count.should == 67
  end
  
  it "should determine the database version" do
    @reader.version.should == "83"
  end
  
end

describe DBF::Reader, "when the in_memory flag is true" do
  
  before(:each) do
    @reader = DBF::Reader.new File.dirname(__FILE__) + '/../test/databases/dbase_iii_memo.dbf'
  end
  
  it "should build the records array from disk only on the first request" do
    @reader.expects(:get_all_records_from_file).at_most_once.returns([])
    3.times { @reader.records }
  end
  
  it "should read from the records array when using the record() method" do
    @reader.expects(:get_all_records_from_file).at_most_once.returns([])
    @reader.expects(:get_record_from_file).never
    @reader.expects(:records).times(2).returns([])
    @reader.record(1)
    @reader.record(10)
  end
  
end

describe DBF::Reader, "when the in_memory flag is false" do
  
  before(:each) do
    @reader = DBF::Reader.new File.dirname(__FILE__) + '/../test/databases/dbase_iii_memo.dbf'
  end
  
  it "should read the records from disk on every request" do
    @reader.in_memory = false
    @reader.expects(:get_all_records_from_file).times(3).returns([])
    3.times { @reader.records }
  end
end

describe DBF::Reader, "schema" do
  
  it "should match test schema " do
    reader = DBF::Reader.new File.dirname(__FILE__) + '/../test/databases/dbase_iii_memo.dbf'
    control_schema = File.read(File.dirname(__FILE__) + '/fixtures/dbase_iii_memo_schema.rb')
    
    reader.schema.should == control_schema
  end
  
end

describe DBF::Reader, "find(index)" do
  
  before(:all) do
    @reader = DBF::Reader.new File.dirname(__FILE__) + '/../test/databases/dbase_iii_memo.dbf'
  end
  
  it "should return the correct record" do
    @reader.find(5).should == @reader.record(5)
  end
  
  it "should raise an error if options are not empty" do
    lambda { @reader.find(5, :name => 'test') }.should raise_error(ArgumentError)
  end
  
end

describe DBF::Reader, "find(:all)" do
  
  before(:all) do
    @reader = DBF::Reader.new File.dirname(__FILE__) + '/../test/databases/dbase_iii_memo.dbf'
  end
  
  it "should return all records if options are empty" do
    @reader.find(:all).should == @reader.records
  end
  
  it "should return matching records when used with options" do
    @reader.find(:all, "WEIGHT" => 0.0).should == @reader.records.select {|r| r["WEIGHT"] == 0.0}
  end
  
  it "with multiple options should search for all search terms as if using AND" do
    @reader.find(:all, "ID" => 30, "IMAGE" => "graphics/00000001/TBC01.jpg").should == []
  end
end

describe DBF::Reader, "find(:first)" do
  
  before(:all) do
    @reader = DBF::Reader.new File.dirname(__FILE__) + '/../test/databases/dbase_iii_memo.dbf'
  end
  
  it "should return the first record if options are empty" do
    @reader.find(:first).should == @reader.records.first
  end
  
  it "should return the first matching record when used with options" do
    @reader.find(:first, "CODE" => "C").should == @reader.record(5)
  end
  
  it "with multiple options should search for all search terms as if using AND" do
    @reader.find(:first, "ID" => 30, "IMAGE" => "graphics/00000001/TBC01.jpg").should be_nil
  end
end

