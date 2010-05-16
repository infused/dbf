require File.expand_path(File.join(File.dirname(__FILE__), "../spec_helper"))

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
    
    context 'with length of 0' do
      specify { lambda { DBF::Column.new "ColumnName", "N", 0, 0 }.should raise_error(DBF::ColumnLengthError) }
    end
    
    context 'with length less than 0' do
      specify { lambda { DBF::Column.new "ColumnName", "N", -1, 0 }.should raise_error(DBF::ColumnLengthError) }
    end
    
    context 'with empty column name' do
      specify { lambda { DBF::Column.new "\xFF\xFC", "N", 1, 0 }.should raise_error(DBF::ColumnNameError) }
    end
  end
  
  context "#type_cast" do
    context 'with type N (number)' do
      context 'with 0 decimals' do
        it 'should cast value to Fixnum' do
          value = "135"
          column = DBF::Column.new "ColumnName", "N", 3, 0
          column.type_cast(value).should be_a Fixnum
          column.type_cast(value).should == 135
        end
      end
      
      context 'with more than 0 decimals' do
        it "should cast value to Float" do
          value = "13.5"
          column = DBF::Column.new "ColumnName", "N", 2, 1
          column.type_cast(value).should be_a Float
          column.type_cast(value).should == 13.5
        end
      end
    end
    
    context 'with type F (float)' do
      it "should cast value to Float" do
        value = "135"
        column = DBF::Column.new "ColumnName", "F", 3, 0
        column.type_cast(value).should be_a Float
        column.type_cast(value).should == 135.0
      end
    end
    
    context 'with type I (integer)' do
      it "should cast value to Fixnum" do
        value = "\203\171\001\000"
        column = DBF::Column.new "ColumnName", "I", 3, 0
        column.type_cast(value).should be_a Fixnum
        column.type_cast(value).should == 96643
      end
    end
    
    context 'with type L (logical/boolean)' do
      it "should cast 'y' to true" do
        value = "y"
        column = DBF::Column.new "ColumnName", "L", 1, 0
        column.type_cast(value).should be_a TrueClass
        column.type_cast(value).should == true
      end
      
      it "should cast 'n' to false" do
        value = "n"
        column = DBF::Column.new "ColumnName", "L", 1, 0
        column.type_cast(value).should be_a FalseClass
        column.type_cast(value).should == false
      end
    end
    
    context 'with type T (datetime)' do
      context 'with valid datetime' do
        it "should cast to DateTime" do
          value = "Nl%\000\300Z\252\003"
          column = DBF::Column.new "ColumnName", "T", 16, 0
          column.type_cast(value).should == "2002-10-10T17:04:56+00:00"
        end
      end
      
      context 'with invalid datetime' do
        it "should cast to nil" do
          value = "Nl%\000\000A\000\999"
          column = DBF::Column.new "ColumnName", "T", 16, 0
          column.type_cast(value).should be_nil
        end
      end
    end
    
    context 'with type D (date)' do
      context 'with valid date' do
        it "should cast to Date" do
          value = "20050712"
          column = DBF::Column.new "ColumnName", "D", 8, 0
          column.type_cast(value).should == Date.new(2005,7,12)
        end
      end
      
      context 'with invalid date' do
        it "should cast to Date" do
          value = "0"
          column = DBF::Column.new "ColumnName", "D", 8, 0
          column.type_cast(value).should be_nil
        end
      end
    end
    
    context 'with type M (memo)' do
      it "should typecast memo columns to String" do
        value = 'abc'
        column = DBF::Column.new "ColumnName", "M", 3, 0
        column.type_cast(value).should be_a String
      end
    end
  end
  
  context "#schema_definition" do
    context 'with type N (number)' do
      it "should output an integer column" do
        column = DBF::Column.new "ColumnName", "N", 1, 0
        column.schema_definition.should == "\"column_name\", :integer\n"
      end
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
