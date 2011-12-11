require "spec_helper"

shared_examples_for 'DBF' do
  specify "sum of column lengths should equal record length specified in header plus one" do
    header_record_length = @table.instance_eval {@record_length}
    sum_of_column_lengths = @table.columns.inject(1) {|sum, column| sum += column.length}
    
    header_record_length.should == sum_of_column_lengths
  end

  specify "records should be instances of DBF::Record" do
    @table.all? {|record| record.should be_an_instance_of(DBF::Record)}
  end
  
  specify "record count should be the same as reported in the header" do
    @table.entries.size.should == @table.record_count
  end
  
  specify "column names should not be blank" do
    @table.columns.all? {|column| column.name.should_not be_empty}
  end
  
  specify "column types should be valid" do
    valid_column_types = %w(C N L D M F B G P Y T I V X @ O + 0)
    @table.columns.all? {|column| valid_column_types.should include(column.type)}
  end
  
  specify "column lengths should be instances of Fixnum" do
    @table.columns.all? {|column| column.length.should be_an_instance_of(Fixnum)}
  end
  
  specify "column lengths should be larger than 0" do
    @table.columns.all? {|column| column.length.should > 0}
  end
  
  specify "column decimals should be instances of Fixnum" do
    @table.columns.all? {|column| column.decimal.should be_an_instance_of(Fixnum)}
  end
  
  specify "column read accessors should return the attribute after typecast" do
    @table.columns do |column|
      record = @table.records.first
      record.send(column.name).should == record[column.name]
    end
  end
  
  specify "column attributes should be accessible in underscored form" do
    @table.columns do |column|
      record = @table.records.first
      record.send(column_name).should == record.send(Util.underscore(column_name))
    end
  end
end

shared_examples_for 'Foxpro DBF' do
  specify "columns should be instances of DBF::FoxproColumn" do
    @table.columns.all? {|column| column.should be_an_instance_of(DBF::Column::Foxpro)}
  end
end

describe DBF, "of type 03 (dBase III without memo file)" do
  before do
    @table = DBF::Table.new "#{DB_PATH}/dbase_03.dbf"
  end
  
  it_should_behave_like "DBF"
  
  it "should report the correct version number" do
    @table.version.should == "03"
  end
  
  it "should report the correct version description" do
    @table.version_description.should == "dBase III without memo file"
  end
  
  it "should determine the number of records" do
    @table.record_count.should == 14
  end
end

describe DBF, "of type 30 (Visual FoxPro)" do
  before do
    @table = DBF::Table.new "#{DB_PATH}/dbase_30.dbf"
  end
  
  it_should_behave_like "DBF"
  
  it "should report the correct version number" do
    @table.version.should == "30"
  end
  
  it "should report the correct version description" do
    @table.version_description.should == "Visual FoxPro"
  end

  it "should determine the number of records" do
    @table.record_count.should == 34
  end
end

describe DBF, "of type 31 (Visual FoxPro with AutoIncrement field)" do
  before do
    @table = DBF::Table.new "#{DB_PATH}/dbase_31.dbf"
  end
  
  it_should_behave_like "DBF"
  
  it "should have a dBase version of 31" do
    @table.version.should == "31"
  end
  
  it "should report the correct version description" do
    @table.version_description.should == "Visual FoxPro with AutoIncrement field"
  end
  
  it "should determine the number of records" do
    @table.record_count.should == 77
  end
end

describe DBF, "of type 83 (dBase III with memo file)" do
  before do
    @table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
  end
  
  it_should_behave_like "DBF"
  
  it "should report the correct version number" do
    @table.version.should == "83"
  end
  
  it "should report the correct version description" do
    @table.version_description.should == "dBase III with memo file"
  end
  
  it "should determine the number of records" do
    @table.record_count.should == 67
  end
end

describe DBF, "of type 8b (dBase IV with memo file)" do
  before do
    @table = DBF::Table.new "#{DB_PATH}/dbase_8b.dbf"
  end
  
  it_should_behave_like "DBF"
  
  it "should report the correct version number" do
    @table.version.should == "8b"
  end
  
  it "should report the correct version description" do
    @table.version_description.should == "dBase IV with memo file"
  end
  
  it "should determine the number of records" do
    @table.record_count.should == 10
  end
end

describe DBF, "of type f5 (FoxPro with memo file)" do
  before do
    @table = DBF::Table.new "#{DB_PATH}/dbase_f5.dbf"
  end
  
  it_should_behave_like "DBF"
  it_should_behave_like "Foxpro DBF"
  
  it "should report the correct version number" do
    @table.version.should == "f5"
  end
  
  it "should report the correct version description" do
    @table.version_description.should == "FoxPro with memo file"
  end
  
  it "should determine the number of records" do
    @table.record_count.should == 975
  end
end