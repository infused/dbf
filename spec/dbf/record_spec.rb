require "spec_helper"

describe DBF::Record do

  describe '#to_a' do
    it 'should return an ordered array of attribute values' do
      table = DBF::Table.new "#{DB_PATH}/dbase_8b.dbf"

      record = table.record(0)
      record.to_a.should == ["One", 1.0, Date.new(1970, 1, 1), true, 1.23456789012346, "First memo\r\n\037 \037 \037 \037 "]

      record = table.record(9)
      record.to_a.should == ["Ten records stored in this database", 10.0, nil, false, 0.1, nil]
    end
  end

  describe '#==' do
    before do
      table = DBF::Table.new "#{DB_PATH}/dbase_8b.dbf"
      @record = table.record(9)
    end

    it 'should be false if other does not have attributes' do
      (@record == mock('other')).should be_false
    end

    it 'should be true if other attributes match' do
      attributes = {:x => 1, :y => 2}
      @record.stub!(:attributes).and_return(attributes)
      other = mock('object', :attributes => attributes)
      (@record == other).should be_true
    end
  end

  describe 'column accessors' do
    let(:table) { DBF::Table.new "#{DB_PATH}/dbase_8b.dbf"}

    it 'should define accessor methods for each column' do
      record = table.find(0)
      record.should respond_to(:character)
      record.character.should == 'One'
    end
  end

  describe 'column data for table' do
    let(:table) { DBF::Table.new "#{DB_PATH}/cp1251.dbf"}

    let(:record) { table.find(0) }
    it 'should automatically encodes to default system encoding' do
      if table.supports_encoding?
        record.name.encoding.should == Encoding.default_external
        record.name.encode("UTF-8").unpack("H4").should == ["d0b0"] # russian a
      end
    end
  end
end
