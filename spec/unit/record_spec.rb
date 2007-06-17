require File.dirname(__FILE__) + "/../spec_helper"

describe DBF::Record, "when initialized" do

  it "should typecast number fields with decimals == 0 to Integer" do
    reader = DBF::Reader.new "#{DB_PATH}/dbase_83.dbf"
    reader.field("ID").type.should == "N"
    reader.field("ID").decimal.should == 0
    reader.records.all? {|record| record["ID"].should be_kind_of(Integer)}
  end
  
  it "should typecast number fields with decimals > 0 to Float" do
    reader = DBF::Reader.new "#{DB_PATH}/dbase_83.dbf"
    reader.field("ID").type.should == "N"
    reader.field("COST").decimal.should == 2
    reader.records.all? {|record| record["COST"].should be_kind_of(Float)}
  end
  
  it "should typecast memo fields to String" do
    reader = DBF::Reader.new "#{DB_PATH}/dbase_83.dbf"
    reader.field("DESC").type.should == "M"
    reader.records.all? {|record| record["DESC"].should be_kind_of(String)}
  end
  
  it "should typecast logical fields to True or False" do
    reader = DBF::Reader.new "#{DB_PATH}/dbase_30.dbf"
    reader.field("WEBINCLUDE").type.should == "L"
    reader.records.all? {|record| record["WEBINCLUDE"].should satisfy {|v| v == true || v == false}}
  end

end
