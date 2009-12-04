describe DBF, :shared => true do
  specify "sum of column lengths should equal record length specified in header" do
    header_record_length = @table.instance_eval {@record_length}
    sum_of_column_lengths = @table.columns.inject(1) {|sum, column| sum + column.length}
    
    header_record_length.should == sum_of_column_lengths
  end

  specify "records should be instances of DBF::Record" do
    @table.records.all? {|record| record.should be_an_instance_of(DBF::Record)}
  end
  
  specify "columns should be instances of DBF::Column" do
    @table.columns.all? {|column| column.should be_an_instance_of(DBF::Column)}
  end
  
  specify "column names should not be blank" do
    @table.columns.all? {|column| column.name.should_not be_empty}
  end
  
  specify "column types should be valid" do
    valid_column_types = %w(C N L D M F B G P Y T I V X @ O +)
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
      record.send(column_name).should == record.send(column_name.underscore)
    end
  end
  
end