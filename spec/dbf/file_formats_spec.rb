require "spec_helper"

shared_examples_for 'DBF' do
  specify "sum of column lengths should equal record length specified in header plus one" do
    header_record_length = table.instance_eval {@header.record_length}
    sum_of_column_lengths = table.columns.inject(1) {|sum, column| sum += column.length}

    expect(header_record_length).to eq sum_of_column_lengths
  end

  specify "records should be instances of DBF::Record" do
    expect(table.all? {|record| record.is_a?(DBF::Record)}).to be_true
  end

  specify "record count should be the same as reported in the header" do
    expect(table.entries.size).to eq table.record_count
  end

  specify "column names should not be blank" do
    expect(table.columns.all? {|column| !column.name.empty?}).to be_true
  end

  specify "column types should be valid" do
    valid_column_types = %w(C N L D M F B G P Y T I V X @ O + 0)
    expect(table.columns.all? {|column| valid_column_types.include?(column.type)}).to be_true
  end

  specify "column lengths should be instances of Fixnum" do
    expect(table.columns.all? {|column| column.length.is_a?(Fixnum)}).to be_true
  end

  specify "column lengths should be larger than 0" do
    expect(table.columns.all? {|column| column.length > 0}).to be_true
  end

  specify "column decimals should be instances of Fixnum" do
    expect(table.columns.all? {|column| column.decimal.is_a?(Fixnum)}).to be_true
  end
end

shared_examples_for 'Foxpro DBF' do
  specify "columns should be instances of DBF::FoxproColumn" do
    expect(table.columns.all? {|column| column.is_a?(DBF::Column::Foxpro)}).to be_true
  end
end

describe DBF, "of type 03 (dBase III without memo file)" do
  let(:table) { DBF::Table.new "#{DB_PATH}/dbase_03.dbf" }

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

describe DBF, "of type 30 (Visual FoxPro)" do
  let(:table) { DBF::Table.new "#{DB_PATH}/dbase_30.dbf" }

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

describe DBF, "of type 30 (Visual FoxPro) x" do
  let(:table) { DBF::Table.new "#{DB_PATH}/dir_alumnos.dbf" }

  it_should_behave_like "DBF"

  it "should report the correct version number" do
    expect(table.version).to eq "30"
  end

  it "should report the correct version description" do
    expect(table.version_description).to eq "Visual FoxPro"
  end

  it "should determine the number of records" do
    expect(table.record_count).to eq 2803
  end

  it "reads memo data" do
    expect(table.record(2764).telf).to eq '0261-2018788'
  end
end

describe DBF, "of type 31 (Visual FoxPro with AutoIncrement field)" do
  let(:table) { DBF::Table.new "#{DB_PATH}/dbase_31.dbf" }

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

describe DBF, "of type 83 (dBase III with memo file)" do
  let(:table) { DBF::Table.new "#{DB_PATH}/dbase_83.dbf" }

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

describe DBF, "of type 8b (dBase IV with memo file)" do
  let(:table) { DBF::Table.new "#{DB_PATH}/dbase_8b.dbf" }

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

describe DBF, "of type f5 (FoxPro with memo file)" do
  let(:table) { DBF::Table.new "#{DB_PATH}/dbase_f5.dbf" }

  it_should_behave_like "DBF"
  it_should_behave_like "Foxpro DBF"

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
    expect(table.record(3).obse).to match(/\Ajos.*pare\.\Z/m)
  end
end
