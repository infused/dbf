require "spec_helper"
require "dbf/dbf_shared"

describe DBF, "of type f5 (FoxPro with memo file)" do
  before do
    @table = DBF::Table.new "#{DB_PATH}/dbase_f5.dbf"
  end
  
  it_should_behave_like "DBF"
  
  it "should report the correct version number" do
    @table.version.should == "f5"
  end
  
end