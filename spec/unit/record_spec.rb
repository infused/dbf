require File.dirname(__FILE__) + "/../spec_helper"

describe DBF::Record, "when initialized" do
  
  def standalone_record(binary_data)
    table = mock
    table.stubs(:data)
    table.data.stubs(:read).returns(binary_data)
    table.stubs(:memo).returns(nil)
    table.stubs(:columns).returns([])
    DBF::Record.new(table)
  end

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
  
  it "should typecast datetime columns to DateTime" do
    binary_data = "Nl%\000\300Z\252\003"
    record = standalone_record(binary_data)
    column = stub(:length => 8)
    
    record.instance_eval {unpack_datetime(column)}.to_s.should == "2002-10-10T17:04:56+00:00"
  end
  
  it "should typecast integers to Fixnum" do
    binary_data = "\017\020\000\000"
    record = standalone_record(binary_data)
    column = stub(:length => 4)
      
    record.instance_eval {unpack_integer(column)}.should == 4111
  end

end
