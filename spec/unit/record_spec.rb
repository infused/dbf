require File.expand_path(File.join(File.dirname(__FILE__), "../spec_helper"))

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
    before do
      @table = mock_table
      @record = DBF::Record.new(@table)
    end
    
    context 'with start_block of 0' do
      specify { @record.send(:read_memo, 0).should be_nil }
    end
    
    context 'with start_block less than 0' do
      specify { @record.send(:read_memo, -1).should be_nil }
    end
    
    context 'with valid start_block' do
      before do
        @table.stub!(:memo_file_format).and_return(:fpt)
      end
      
      it 'should build the fpt memo' do
        @record.should_receive(:build_fpt_memo)
        @record.send(:read_memo, 1)
      end 
    end
    
    context 'with no memo file' do
      specify do 
        @table.should_receive(:has_memo_file?).and_return(false)
        @record.send(:read_memo, 5).should be_nil
      end
    end
  end
  
  describe '#to_a' do
    it 'should return an ordered array of attribute values' do
      table = DBF::Table.new "#{DB_PATH}/dbase_8b.dbf"
      record = table.record(9)
      record.to_a.should == ["Ten records stored in this database", 10.0, nil, false, 0.1, nil]
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
