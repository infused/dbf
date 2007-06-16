require File.dirname(__FILE__) + "/../spec_helper"
require File.dirname(__FILE__) + "/dbf_shared"

describe DBF, "of type 30 (Visual FoxPro)" do
  before(:each) do
    @reader = DBF::Reader.new "#{DB_PATH}/visual_foxpro.dbf"
  end
  
  it_should_behave_like "DBF"
  
  it "should report the correct version number" do
    @reader.version.should == "30"
  end
  
  it "should have a memo file" do
    @reader.should have_memo_file
  end
  
  it "should report the correct memo type" do
    @reader.memo_file_format.should == :fpt
  end
  
end