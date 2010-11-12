require "spec_helper"
require "dbf/dbf_shared"

describe DBF, "of type 8b (dBase IV with memo file)" do
  before do
    @table = DBF::Table.new "#{DB_PATH}/dbase_8b.dbf"
  end
  
  it_should_behave_like "DBF"
  
  it "should report the correct version number" do
    @table.version.should == "8b"
  end
  
end