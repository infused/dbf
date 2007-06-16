require File.dirname(__FILE__) + "/../spec_helper"

describe DBF::Field, "when initialized" do
  
  before(:each) do
    @field = DBF::Field.new "FieldName", "N", 1, 0
  end
  
  it "should set the #name accessor" do
    @field.name.should == "FieldName"
  end
  
  it "should set the #type accessor" do
    @field.type.should == "N"
  end
  
  it "should set the #length accessor" do
    @field.length.should == 1
  end
  
  it "should set the #decimal accessor" do
    @field.decimal.should == 0
  end
  
  it "should raise an error if length is greater than 0" do
    lambda { field = DBF::Field.new "FieldName", "N", -1, 0 }.should raise_error(DBF::FieldLengthError)
  end
  
  it "should strip null characters from the name" do
    field = DBF::Field.new "Field\0Name\0", "N", 1, 0
    field.name.should == "FieldName"
  end
  
end