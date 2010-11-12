require "spec_helper"
require "dbf/dbf_shared"

describe DBF, "of type 83 (dBase III with memo file)" do
  before do
    @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
  end
  
  it_should_behave_like "DBF"
  
  it "should report the correct version number" do
    @table.version.should == "83"
  end
  
end