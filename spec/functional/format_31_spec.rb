require File.expand_path(File.join(File.dirname(__FILE__), "../spec_helper"))
require File.expand_path(File.join(File.dirname(__FILE__), "dbf_shared"))

describe DBF, "of type 31 (Visual FoxPro with AutoIncrement field)" do
  before do
    @table = DBF::Table.new "#{DB_PATH}/dbase_31.dbf"
  end
  
  it_should_behave_like "DBF"
  
  it "should have a dBase version of 31" do
    @table.version.should == "31"
  end
  
  it "should have a memo file" do
    @table.should_not have_memo_file
  end
  
  it "should have a nil memo_file_format" do
    @table.memo_file_format.should be_nil
  end
  
end