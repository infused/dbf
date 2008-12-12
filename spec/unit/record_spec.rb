require File.dirname(__FILE__) + "/../spec_helper"

describe DBF::Record do
  
  def example_record(data = '')
    DBF::Record.new(mock_table(data))
  end
  
  def mock_table(data = '')
    table = mock('table')
    table.stub!(:memo_block_size).and_return(8)
    table.stub!(:memo).and_return(nil)
    table.stub!(:columns).and_return([])
    table.stub!(:data)
    table.stub!(:has_memo_file?).and_return(true)
    table.data.stub!(:read).and_return(data)
    table
  end
  
  context "when initialized" do
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
      record = example_record("Nl%\000\300Z\252\003")
      column = mock('column', :length => 8)
  
      record.instance_eval {unpack_datetime(column)}.to_s.should == "2002-10-10T17:04:56+00:00"
    end
  
    it "should typecast integers to Fixnum" do
      record = example_record("\017\020\000\000")
      column = mock('column', :length => 4)
  
      record.instance_eval {unpack_integer(column)}.should == 4111
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
  
  describe "#typecase_column" do
    before do
      @table = mock_table
      @column = mock('column')
      @column.stub!(:name).and_return('created')
      @column.stub!(:length).and_return(8)
      @column.stub!(:type).and_return('D')
      @table.stub!(:columns).and_return([@column])
      @record = DBF::Record.new(@table)
    end
    
    describe 'when column is type D' do
      it 'should return Time' do
        @record.stub!(:unpack_string).and_return('20080606')
        @record.send(:typecast_column, @column).should == Time.gm(2008, 6, 6)
      end
    
      it 'should return Date if Time is out of range' do
        @record.stub!(:unpack_string).and_return('19440606')
        @record.send(:typecast_column, @column).should == Date.new(1944, 6, 6)
      end
    end
    
  end

end
