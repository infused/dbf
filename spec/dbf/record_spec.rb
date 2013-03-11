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
    let :record do
      table = DBF::Table.new "#{DB_PATH}/dbase_8b.dbf"
      table.record(9)
    end
    
    describe 'when other does not have attributes' do
      it 'is false' do
        (record == mock('other')).should be_false
      end
    end

    describe 'if other attributes match' do
      it 'is true' do
        attributes = {:x => 1, :y => 2}
        record.stub!(:attributes).and_return(attributes)
        other = mock('object', :attributes => attributes)
        (record == other).should be_true
      end
    end
    
  end

  describe 'column accessors' do
    let(:table) { DBF::Table.new "#{DB_PATH}/dbase_8b.dbf"}
    let(:record) { table.find(0) }

    it 'should have dynamic accessors for the columns' do
      record.should respond_to(:character)
      record.character.should == 'One'
      record.float.should == 1.23456789012346
      record.logical.should == true
    end

    it 'should not define accessor methods on the base class' do
      second_table = DBF::Table.new "#{DB_PATH}/dbase_03.dbf"
      second_record = second_table.find(0)
      record.character.should == 'One'
      expect { second_record.character }.to raise_error(NoMethodError)
    end
  end

  describe 'column data for table' do
    describe 'using specified in dbf encoding' do
      let(:table) { DBF::Table.new "#{DB_PATH}/cp1251.dbf"}

      let(:record) { table.find(0) }
      it 'should automatically encodes to default system encoding' do
        if table.supports_encoding?
          record.name.encoding.should == Encoding.default_external
          record.name.encode("UTF-8").unpack("H4").should == ["d0b0"] # russian a
        end
      end
    end

    describe 'overriding specified in dbf encoding' do
      let(:table) { DBF::Table.new "#{DB_PATH}/cp1251.dbf", nil, 'cp866'}

      let(:record) { table.find(0) }
      it 'should transcode from manually specified encoding to default system encoding' do
        if table.supports_encoding?
          record.name.encoding.should == Encoding.default_external
          record.name.encode("UTF-8").unpack("H4").should == ["d180"] # russian а encoded in cp1251 and read as if it was encoded in cp866
        end
      end
    end
  end
  
  describe '#attributes' do
    let(:table) { DBF::Table.new "#{DB_PATH}/dbase_8b.dbf"}
    let(:record) { table.find(0) }
    
    it 'is a hash of attribute name/value pairs' do
      record.attributes.should be_a(Hash)
      record.attributes['CHARACTER'] == 'One'
    end
    
    it 'has only original field names as keys' do
      original_field_names = %w(CHARACTER DATE FLOAT LOGICAL MEMO NUMERICAL)
      record.attributes.keys.sort.should == original_field_names
    end
  end
end
