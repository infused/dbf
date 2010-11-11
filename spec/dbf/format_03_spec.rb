require "spec_helper"
require "dbf/dbf_shared"

describe DBF, "of type 03 (dBase III without memo file)" do
  before do
    @table = DBF::Table.new "#{DB_PATH}/dbase_03.dbf"
  end
  
  it_should_behave_like "DBF"
  
  it "should report the correct version number" do
    @table.version.should == "03"
  end
  
  it "should not have a memo file" do
    @table.memo.should be_nil
  end
  
end