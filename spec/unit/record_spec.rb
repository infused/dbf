require File.dirname(__FILE__) + "/../spec_helper"

describe DBF::Record do
  
  def example_record(data = '')
    table = mock_table(data)
    DBF::Record.new(table)
  end
  
  def mock_table(data = '')
    @column1 = DBF::Column.new 'ColumnName', 'N', 1, 0
    
    returning mock('table') do |table|
      table.stub!(:memo_block_size).and_return(8)
      table.stub!(:memo).and_return(nil)
      table.stub!(:columns).and_return([@column1])
      table.stub!(:data).and_return(data)
      table.stub!(:has_memo_file?).and_return(true)
      table.data.stub!(:read).and_return(data)
    end
  end
  
  context "when initialized" do
    it "should typecast number columns no decimal places to Integer" do
      table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      table.column("ID").type.should == "N"
      table.column("ID").decimal.should == 0
      table.records.all? {|record| record.attributes['id'].should be_kind_of(Integer)}
    end
  
    it "should typecast number columns with decimals > 0 to Float" do
      table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      table.column("ID").type.should == "N"
      table.column("COST").decimal.should == 2
      table.records.all? {|record| record.attributes['cost'].should be_kind_of(Float)}
    end
  
    it "should typecast memo columns to String" do
      table = DBF::Table.new "#{DB_PATH}/dbase_83.dbf"
      table.column("DESC").type.should == "M"
      table.records.all? {|record| record.attributes['desc'].should be_kind_of(String)}
    end
  
    it "should typecast logical columns to True or False" do
      table = DBF::Table.new "#{DB_PATH}/dbase_30.dbf"
      table.column("WEBINCLUDE").type.should == "L"
      table.records.all? {|record| record.attributes["webinclude"].should satisfy {|v| v == true || v == false}}
    end
  end
  
  describe '#memo_block_content_size' do
    it "should equal the difference between the table's memo_block_size and 8" do
      table = mock_table
      table.should_receive(:memo_block_size).and_return(128)
      record = DBF::Record.new(table)
      
      record.send(:memo_block_content_size).should == 120
    end
  end
  
  describe '#memo_content_size' do
    it "should equal 8 plus the difference between memo_size and the table's memo_block_size" do
      record = example_record
      record.should_receive(:memo_block_size).and_return(8)
      
      record.send(:memo_content_size, 1024).should == 1024
    end
  end
  
  describe '#read_memo' do
    it 'should return nil if start_block is less than 1' do
      table = mock_table
      record = DBF::Record.new(table)
      
      record.send(:read_memo, 0).should be_nil
      record.send(:read_memo, -1).should be_nil
    end
    
    it 'should return nil if memo file is missing' do
      table = mock_table
      table.should_receive(:has_memo_file?).and_return(false)
      record = DBF::Record.new(table)
      
      record.send(:read_memo, 5).should be_nil
    end
  end
  
  describe '#to_a' do
    it 'should return an ordered array of attribute values' do
      table = DBF::Table.new "#{DB_PATH}/dbase_8b.dbf"
      record = table.records[9]
      record.to_a.should == ["Ten records stored in this database", 10.0, nil, false, "0.100000000000000000", nil]
    end
  end
  
  describe '#==' do
    before do
      @record = example_record
    end
    
    it 'should be false if other does not have attributes' do
      other = mock('object')
      (@record == other).should be_false
    end
    
    it 'should be true if other attributes match' do
      attributes = {:x => 1, :y => 2}
      @record.stub!(:attributes).and_return(attributes)
      other = mock('object', :attributes => attributes)
      (@record == other).should be_true
    end
  end
  
  describe 'unpack_data' do
    before do
      @record = example_record('abc')
    end
    
    it 'should unpack the data' do
      @record.send(:unpack_data, 3).should == 'abc'
    end
  end

end
