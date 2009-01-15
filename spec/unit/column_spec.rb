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
      lambda { DBF::Column.new "ColumnName", "N", -1, 0 }.should raise_error(DBF::ColumnLengthError)
    end
    
    it "should raise error on emtpy column names" do
      lambda { DBF::Column.new "\xFF\xFC", "N", 1, 0 }.should raise_error(DBF::ColumnNameError)
    end
    
  end
  
  context "#type_cast" do
    it "should cast numbers with decimals to Float" do
      value = "13.5"
      column = DBF::Column.new "ColumnName", "N", 2, 1
      column.type_cast(value).should == 13.5
    end
    
    it "should cast numbers with no decimals to Integer" do
      value = "135"
      column = DBF::Column.new "ColumnName", "N", 3, 0
      column.type_cast(value).should == 135
    end
    
    it "should cast :integer to Integer" do
      value = "135"
      column = DBF::Column.new "ColumnName", "I", 3, 0
      column.type_cast(value).should == 135
    end
    
    it "should cast boolean to True" do
      value = "y"
      column = DBF::Column.new "ColumnName", "L", 1, 0
      column.type_cast(value).should == true
    end
    
    it "should cast boolean to False" do
      value = "n"
      column = DBF::Column.new "ColumnName", "L", 1, 0
      column.type_cast(value).should == false
    end
    
    it "should cast :datetime columns to DateTime" do
      value = "Nl%\000\300Z\252\003"
      column = DBF::Column.new "ColumnName", "T", 16, 0
      column.type_cast(value).should == "2002-10-10T17:04:56+00:00"
    end
    
    it "should cast :date columns to Date" do
      value = "20050712"
      column = DBF::Column.new "ColumnName", "D", 8, 0
      column.type_cast(value).should == Date.new(2005,7,12)
    end
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
    before do
      @column = DBF::Column.new "ColumnName", "N", 1, 0
    end
    
    it "should strip characters below decimal 32 and above decimal 127" do
      @column.strip_non_ascii_chars("--\x1F-\x68\x65\x6C\x6C\x6F world-\x80--").should == "---hello world---"
    end

    it "should truncate characters with decimal 0" do
      @column.strip_non_ascii_chars("--\x1F-\x68\x65\x6C\x6C\x6F \x00 world-\x80--").should == "---hello "
    end
  end
  
end
