describe DBF, :shared => true do
  specify "number of records found should equal number of records calculated from the header information" do
    @reader.record_count.should == @reader.records.size
  end
  
  specify "sum of field lengths should equal record length specified in header" do
    header_record_length = @reader.instance_eval {@record_length}
    sum_of_field_lengths = @reader.fields.inject(1) {|sum, field| sum + field.length}
    
    header_record_length.should == sum_of_field_lengths
  end

  specify "records should be instances of DBF::Record" do
    @reader.records.all? {|record| record.should be_an_instance_of(DBF::Record)}
  end
  
  specify "fields should be instances of DBF::Field" do
    @reader.fields.all? {|field| field.should be_an_instance_of(DBF::Field)}
  end
  
  specify "field names should not be blank" do
    @reader.fields.all? {|field| field.name.should_not be_empty}
  end
  
  specify "field types should be valid" do
    valid_field_types = %w(C N L D M F B G P Y T I V X @ O +)
    @reader.fields.all? {|field| valid_field_types.should include(field.type)}
  end
  
  specify "field lengths should be instances of Fixnum" do
    @reader.fields.all? {|field| field.length.should be_an_instance_of(Fixnum)}
  end
  
  specify "field lengths should be larger than 0" do
    @reader.fields.all? {|field| field.length.should > 0}
  end
  
  specify "field decimals should be instances of Fixnum" do
    @reader.fields.all? {|field| field.decimal.should be_an_instance_of(Fixnum)}
  end
  
end