require File.dirname(__FILE__) + "/../spec_helper"

describe DBF::EnumTable do
  
  describe "#find" do
    describe "with index" do
      it "should return the correct record" do
        table = DBF::EnumTable.new "#{DB_PATH}/dbase_83.dbf"
        table.find(5).should == table.record(5)
      end
    end

    describe "with :all" do
      before do
        @table = DBF::EnumTable.new "#{DB_PATH}/dbase_83.dbf"
      end

      it "should return all records if options are empty" do
        @table.find(:all).should == @table.records
      end

      it "should return matching records when used with options" do
        @table.find(:all, "WEIGHT" => 0.0).should == @table.select {|r| r.attributes["weight"] == 0.0}
      end

      it "should AND multiple search terms" do
        @table.find(:all, "ID" => 30, "IMAGE" => "graphics/00000001/TBC01.jpg").should == []
      end
      
      it "should match original column names" do
        @table.find(:all, "WEIGHT" => 0.0).should_not be_empty
      end
      
      it "should match symbolized column names" do
        @table.find(:all, :WEIGHT => 0.0).should_not be_empty
      end
      
      it "should match downcased column names" do
        @table.find(:all, "weight" => 0.0).should_not be_empty
      end
      
      it "should match symbolized downcased column names" do
        @table.find(:all, :weight => 0.0).should_not be_empty
      end
    end

    describe "with :first" do
      before do
        @table = DBF::EnumTable.new "#{DB_PATH}/dbase_83.dbf"
      end

      it "should return the first record if options are empty" do
        @table.find(:first).should == @table.records.first
      end

      it "should return the first matching record when used with options" do
        @table.find(:first, "CODE" => "C").should == @table.record(5)
      end

      it "should AND multiple search terms" do
        @table.find(:first, "ID" => 30, "IMAGE" => "graphics/00000001/TBC01.jpg").should be_nil
      end
    end
  end
  
  describe '#each' do
    it 'should enumerate all records' do
      table = DBF::EnumTable.new "#{DB_PATH}/dbase_83.dbf"
      records = []
      table.each do |record|
        records << record
      end

      records.map! { |r| r.attributes }
      records.should == table.records.map {|r| r.attributes}
    end
  end

end

