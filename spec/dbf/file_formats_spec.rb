require "spec_helper"

RSpec.shared_examples_for 'DBF' do
  specify "sum of column lengths should equal record length specified in header plus one" do
    header_record_length = table.instance_eval {@header.record_length}
    sum_of_column_lengths = table.columns.inject(1) {|sum, column| sum += column.length}

    expect(header_record_length).to eq sum_of_column_lengths
  end

  specify "records should be instances of DBF::Record" do
    table.each do |record|
      expect(record).to be_kind_of(DBF::Record)
    end
  end

  specify "record count should be the same as reported in the header" do
    expect(table.entries.size).to eq table.record_count
  end

  specify "column names should not be blank" do
    table.columns.each do |column|
      expect(column.name).not_to be_empty
    end
  end

  specify "column types should be valid" do
    valid_column_types = %w(C N L D M F B G P Y T I V X @ O + 0)
    table.columns.each do |column|
      expect(valid_column_types).to include(column.type)
    end
  end

  specify "column lengths should be instances of Fixnum" do
    table.columns.each do |column|
      expect(column.length).to be_kind_of(Fixnum)
    end
  end

  specify "column lengths should be larger than 0" do
    table.columns.each do |column|
      expect(column.length).to be > 0
    end
  end

  specify "column decimals should be instances of Fixnum" do
    table.columns.each do |column|
      expect(column.decimal).to be_kind_of(Fixnum)
    end
  end
end

RSpec.describe DBF, "of type 03 (dBase III without memo file)" do
  let(:table) { DBF::Table.new fixture('dbase_03.dbf') }

  it_should_behave_like "DBF"

  it "should report the correct version number" do
    expect(table.version).to eq "03"
  end

  it "should report the correct version description" do
    expect(table.version_description).to eq "dBase III without memo file"
  end

  it "should determine the number of records" do
    expect(table.record_count).to eq 14
  end
end

RSpec.describe DBF, "of type 30 (Visual FoxPro)" do
  let(:table) { DBF::Table.new fixture('dbase_30.dbf') }

  it_should_behave_like "DBF"

  it "should report the correct version number" do
    expect(table.version).to eq "30"
  end

  it "should report the correct version description" do
    expect(table.version_description).to eq "Visual FoxPro"
  end

  it "should determine the number of records" do
    expect(table.record_count).to eq 34
  end

  it "reads memo data" do
    expect(table.record(3).classes).to match(/\AAgriculture.*Farming\r\n\Z/m)
  end
end

RSpec.describe DBF, "of type 31 (Visual FoxPro with AutoIncrement field)" do
  let(:table) { DBF::Table.new fixture('dbase_31.dbf') }

  it_should_behave_like "DBF"

  it "should have a dBase version of 31" do
    expect(table.version).to eq "31"
  end

  it "should report the correct version description" do
    expect(table.version_description).to eq "Visual FoxPro with AutoIncrement field"
  end

  it "should determine the number of records" do
    expect(table.record_count).to eq 77
  end
end

RSpec.describe DBF, "of type 83 (dBase III with memo file)" do
  let(:table) { DBF::Table.new fixture('dbase_83.dbf') }

  it_should_behave_like "DBF"

  it "should report the correct version number" do
    expect(table.version).to eq "83"
  end

  it "should report the correct version description" do
    expect(table.version_description).to eq "dBase III with memo file"
  end

  it "should determine the number of records" do
    expect(table.record_count).to eq 67
  end
end

RSpec.describe DBF, "of type 8b (dBase IV with memo file)" do
  let(:table) { DBF::Table.new fixture('dbase_8b.dbf') }

  it_should_behave_like "DBF"

  it "should report the correct version number" do
    expect(table.version).to eq "8b"
  end

  it "should report the correct version description" do
    expect(table.version_description).to eq "dBase IV with memo file"
  end

  it "should determine the number of records" do
    expect(table.record_count).to eq 10
  end
end

RSpec.describe DBF, "of type f5 (FoxPro with memo file)" do
  let(:table) { DBF::Table.new fixture('dbase_f5.dbf') }

  it_should_behave_like "DBF"

  it "should report the correct version number" do
    expect(table.version).to eq "f5"
  end

  it "should report the correct version description" do
    expect(table.version_description).to eq "FoxPro with memo file"
  end

  it "should determine the number of records" do
    expect(table.record_count).to eq 975
  end

  it "reads memo data" do
    expect(table.record(3).datn.to_s).to eq '1870-06-30'
  end
end
