require File.dirname(__FILE__) + "/../spec_helper"
require File.dirname(__FILE__) + "/dbf_shared"

describe DBF, "of type 03 (dBase III without memo file)" do
  before(:each) do
    @reader = DBF::Reader.new "#{DB_PATH}/dbase_03.dbf"
  end
  
  it_should_behave_like "DBF"
  
  it "should report the correct version number" do
    @reader.version.should == "03"
  end
  
  it "should have a memo file" do
    @reader.should_not have_memo_file
  end
  
  it "should report the correct memo type" do
    @reader.memo_file_format.should be_nil
  end
  
end