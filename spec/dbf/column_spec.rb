require "spec_helper"

describe DBF::Column::Dbase do
  
  context "when initialized" do
    let(:column) { DBF::Column::Dbase.new "ColumnName", "N", 1, 0, "30" }
    
    it "sets the #name accessor" do
      column.name.should == "ColumnName"
    end
    
    it "sets the #type accessor" do
      column.type.should == "N"
    end
    
    it "sets the #length accessor" do
      column.length.should == 1
    end
    
    it "sets the #decimal accessor" do
      column.decimal.should == 0
    end
    
    describe 'with length of 0' do
      specify { lambda { DBF::Column::Dbase.new "ColumnName", "N", 0, 0, "30" }.should raise_error(DBF::Column::LengthError) }
    end
    
    describe 'with length less than 0' do
      specify { lambda { DBF::Column::Dbase.new "ColumnName", "N", -1, 0, "30" }.should raise_error(DBF::Column::LengthError) }
    end
    
    describe 'with empty column name' do
      specify { lambda { DBF::Column::Dbase.new "\xFF\xFC", "N", 1, 0, "30" }.should raise_error(DBF::Column::NameError) }
    end
  end
  
  context '#type_cast' do
    context 'with type N (number)' do
      context 'and 0 decimals' do
        it 'casts value to Fixnum' do
          value = '135'
          column = DBF::Column::Dbase.new "ColumnName", "N", 3, 0, "30"
          column.type_cast(value).should be_a(Fixnum)
          column.type_cast(value).should == 135
        end
      end
      
      context 'and more than 0 decimals' do
        it 'casts value to Float' do
          value = '13.5'
          column = DBF::Column::Dbase.new "ColumnName", "N", 2, 1, "30"
          column.type_cast(value).should be_a(Float)
          column.type_cast(value).should == 13.5
        end
      end
    end
    
    context 'with type F (float)' do
      it 'casts value to Float' do
        value = '135'
        column = DBF::Column::Dbase.new "ColumnName", "F", 3, 0, "30"
        column.type_cast(value).should be_a(Float)
        column.type_cast(value).should == 135.0
      end
    end
    
    context 'with type I (integer)' do
      it "casts value to Fixnum" do
        value = "\203\171\001\000"
        column = DBF::Column::Dbase.new "ColumnName", "I", 3, 0, "30"
        column.type_cast(value).should == 96643
      end
    end
    
    context 'with type L (logical/boolean)' do
      let(:column) { DBF::Column::Dbase.new "ColumnName", "L", 1, 0, "30" }
      
      it "casts 'y' to true" do
        column.type_cast('y').should == true
      end
      
      it "casts 't' to true" do
        column.type_cast('t').should == true
      end
      
      it "casts value other than 't' or 'y' to false" do
        column.type_cast('n').should == false
      end
    end
    
    context 'with type T (datetime)' do
      let(:column) { DBF::Column::Dbase.new "ColumnName", "T", 16, 0, "30" }
      
      context 'with valid datetime' do
        it "casts to DateTime" do
          column.type_cast("Nl%\000\300Z\252\003").should == DateTime.parse("2002-10-10T17:04:56+00:00")
        end
      end
      
      context 'when requiring mathn' do
        it "casts to DateTime" do
          lambda do
            require 'mathn'
            column.type_cast("Nl%\000\300Z\252\003")
          end.call.should == DateTime.parse("2002-10-10T17:04:56+00:00")
        end
      end
      
      context 'with invalid datetime' do
        it "casts to nil" do
          column.type_cast("Nl%\000\000A\000\999").should be_nil
        end
      end
    end
    
    context 'with type D (date)' do
      let(:column) { DBF::Column::Dbase.new "ColumnName", "D", 8, 0, "30" }
      
      context 'with valid date' do
        it "casts to Date" do
          column.type_cast("20050712").should == Date.new(2005,7,12)
        end
      end
      
      context 'with invalid date' do
        it "casts to nil" do
          column.type_cast("0").should be_nil
        end
      end
    end
    
    context 'with type M (memo)' do
      it "casts to string" do
        column = DBF::Column::Dbase.new "ColumnName", "M", 3, 0, "30"
        column.type_cast('abc').should be_a(String)
      end
    end
  end
  
  context "#schema_definition" do
    context 'with type N (number)' do
      it "outputs an integer column" do
        column = DBF::Column::Dbase.new "ColumnName", "N", 1, 0, "30"
        column.schema_definition.should == "\"column_name\", :integer\n"
      end
    end
    
    context "with type B (binary)" do
      context "with Foxpro dbf" do
        context "when decimal is greater than 0" do
          it "outputs an float column" do
            column = DBF::Column::Dbase.new "ColumnName", "B", 1, 2, "f5"
            column.schema_definition.should == "\"column_name\", :float\n"
          end
        end
        
        context "when decimal is 0" do
          column = DBF::Column::Dbase.new "ColumnName", "B", 1, 0, "f5"
          column.schema_definition.should == "\"column_name\", :integer\n"
        end
      end
      
      context "when non-Foxpro dbf" do
        it "outputs a text column" do
          
        end
      end
    end
    
    it "defines a float colmn if type is (N)umber with more than 0 decimals" do
      column = DBF::Column::Dbase.new "ColumnName", "N", 1, 2, "30"
      column.schema_definition.should == "\"column_name\", :float\n"
    end
    
    it "defines a date column if type is (D)ate" do
      column = DBF::Column::Dbase.new "ColumnName", "D", 8, 0, "30"
      column.schema_definition.should == "\"column_name\", :date\n"
    end
    
    it "defines a datetime column if type is (D)ate" do
      column = DBF::Column::Dbase.new "ColumnName", "T", 16, 0, "30"
      column.schema_definition.should == "\"column_name\", :datetime\n"
    end
    
    it "defines a boolean column if type is (L)ogical" do
      column = DBF::Column::Dbase.new "ColumnName", "L", 1, 0, "30"
      column.schema_definition.should == "\"column_name\", :boolean\n"
    end
    
    it "defines a text column if type is (M)emo" do
      column = DBF::Column::Dbase.new "ColumnName", "M", 1, 0, "30"
      column.schema_definition.should == "\"column_name\", :text\n"
    end
    
    it "defines a string column with length for any other data types" do
      column = DBF::Column::Dbase.new "ColumnName", "X", 20, 0, "30"
      column.schema_definition.should == "\"column_name\", :string, :limit => 20\n"
    end
  end
  
  context "#name" do    
    it "contains only ASCII characters" do
      column = DBF::Column::Dbase.new "--\x1F-\x68\x65\x6C\x6C\x6F world-\x80--", "N", 1, 0, "30"
      column.name.should == "---hello world---"
    end

    it "is truncated at the null character" do
      column = DBF::Column::Dbase.new "--\x1F-\x68\x65\x6C\x6C\x6F \x00 world-\x80--", "N", 1, 0, "30"
      column.name.should == "---hello "
    end
  end
  
  context '#decode_date' do
    let(:column) { DBF::Column::Dbase.new "ColumnName", "N", 1, 0, "30" }
    
    it 'is nil if value is blank' do
      column.send(:decode_date, '').should be_nil
    end
    
    it 'interperets spaces as zeros' do
      column.send(:decode_date, '2010 715').should == Date.parse('20100715')
    end
  end
  
end
