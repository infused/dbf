require File.dirname(__FILE__) + "/spec_helper"

describe DBF::Record, "when initialized" do
  
  before(:each) do
    @reader = DBF::Reader.new File.dirname(__FILE__) + '/../test/databases/dbase_iii_memo.dbf'
    @record = @reader.record(5)
  end
  
  it "should typecast number fields with decimals == 0 to Integer" do
    @reader.field("ID").type == "N"
    @reader.field("ID").decimal.should == 0
    @record["ID"].should be_kind_of(Integer)
  end
  
  it "should typecast number fields with decimals > 0 to Float" do
    @reader.field("ID").type == "N"
    @reader.field("COST").decimal.should == 2
    @record["COST"].should be_kind_of(Float)
  end
  
  it "should typecast memo fields to String" do
    @reader.field("DESC").type == "M"
    @record["DESC"].should be_kind_of(String)
  end
  
  it "should typecast logical fields to True or False" do
    @reader.field("TAXABLE").type == "L"
    @record["TAXABLE"].should be_kind_of(FalseClass)
  end
  
end