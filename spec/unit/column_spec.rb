require File.dirname(__FILE__) + "/../spec_helper"

describe DBF::Column, "when initialized" do
  
  before(:each) do
    @column = DBF::Column.new "ColumnName", "N", 1, 0
  end
  
  it "should set the #name accessor" do
    @column.name.should == "ColumnName"
  end
  
  it "should set the #type accessor" do
    @column.type.should == "N"
  end
  
  it "should set the #length accessor" do
    @column.length.should == 1
  end
  
  it "should set the #decimal accessor" do
    @column.decimal.should == 0
  end
  
  it "should raise an error if length is greater than 0" do
    lambda { column = DBF::Column.new "ColumnName", "N", -1, 0 }.should raise_error(DBF::ColumnLengthError)
  end
  
  it "should strip null characters from the name" do
    column = DBF::Column.new "Column\0Name\0", "N", 1, 0
    column.name.should == "ColumnName"
  end
  
end