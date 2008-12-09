require File.dirname(__FILE__) + "/../spec_helper"

describe DBF::Column do
  
  context "when initialized" do
    before do
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
  end
  
  context "#type_cast" do
    
  end
  
  context "#schema_definition" do
    it "should define an integer column if type is (N)umber with 9 decimals" do
      column = DBF::Column.new "ColumnName", "N", 1, 0
      column.schema_definition.should == "\"column_name\", :integer\n"
    end
    
    it "should define a float colmn if type is (N)umber with more than 0 decimals" do
      column = DBF::Column.new "ColumnName", "N", 1, 2
      column.schema_definition.should == "\"column_name\", :float\n"
    end
    
    it "should define a date column if type is (D)ate" do
      column = DBF::Column.new "ColumnName", "D", 8, 0
      column.schema_definition.should == "\"column_name\", :date\n"
    end
    
    it "should define a datetime column if type is (D)ate" do
      column = DBF::Column.new "ColumnName", "T", 16, 0
      column.schema_definition.should == "\"column_name\", :datetime\n"
    end
    
    it "should define a boolean column if type is (L)ogical" do
      column = DBF::Column.new "ColumnName", "L", 1, 0
      column.schema_definition.should == "\"column_name\", :boolean\n"
    end
    
    it "should define a text column if type is (M)emo" do
      column = DBF::Column.new "ColumnName", "M", 1, 0
      column.schema_definition.should == "\"column_name\", :text\n"
    end
    
    it "should define a string column with length for any other data types" do
      column = DBF::Column.new "ColumnName", "X", 20, 0
      column.schema_definition.should == "\"column_name\", :string, :limit => 20\n"
    end
  end
  
  context "#strip_non_ascii_chars" do
    it "should strip characters below decimal 32 and above decimal 128" do
      column = DBF::Column.new "ColumnName", "N", 1, 0
      column.send(:strip_non_ascii_chars, "--\x1F-\x68\x65\x6C\x6C\x6F world-\x80--").should == "---hello world---"
    end
  end
  
end