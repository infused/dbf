require File.dirname(__FILE__) + "/../spec_helper"

describe DBF::Record, "when initialized" do

  it "should typecast number columns with decimals == 0 to Integer" do
    table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
    table.column("ID").type.should == "N"
    table.column("ID").decimal.should == 0
    table.records.all? {|record| record.attributes['ID'].should be_kind_of(Integer)}
  end
  
  it "should typecast number columns with decimals > 0 to Float" do
    table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
    table.column("ID").type.should == "N"
    table.column("COST").decimal.should == 2
    table.records.all? {|record| record.attributes['COST'].should be_kind_of(Float)}
  end
  
  it "should typecast memo columns to String" do
    table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
    table.column("DESC").type.should == "M"
    table.records.all? {|record| record.attributes['DESC'].should be_kind_of(String)}
  end
  
  it "should typecast logical columns to True or False" do
    table = DBF::Table.new "#{DB_PATH}/dbase_30.dbf"
    table.column("WEBINCLUDE").type.should == "L"
    table.records.all? {|record| record.attributes["WEBINCLUDE"].should satisfy {|v| v == true || v == false}}
  end

end
