module CommonTests
  module Read
    
    def test_version
      assert_equal @controls[:version], @dbf.version
      assert_equal @dbf.instance_eval("DBF::VERSION_DESCRIPTIONS['#{@dbf.version}']"), @dbf.version_description
    end
    
    def test_has_memo_file
      assert_equal @controls[:has_memo_file], @dbf.has_memo_file?
    end
    
    def test_memo_file_format
      assert_equal @controls[:memo_file_format], @dbf.memo_file_format
    end
    
    def test_records
      assert_kind_of Array, @dbf.records
      assert_kind_of Array, @dbf.rows
      assert(@dbf.records.all? {|record| record.is_a?(DBF::Record)})
    end
    
    # Does the header info match the actual fields found?
    def test_field_count
      assert_equal @controls[:field_count], @dbf.field_count
      assert_equal @dbf.field_count, @dbf.fields.size, "header field_count does not equal actual field count"
    end
    
    # Does the header info match the actual number of records found?
    def test_record_count
      assert_equal @controls[:record_count], @dbf.record_count
      assert_equal @dbf.record_count, @dbf.records.size, "header record_count does not equal actual record count"
    end
    
    def test_record_length
      assert_equal @controls[:record_length], @dbf.instance_eval {@record_length}
      assert_equal @controls[:record_length], @dbf.fields.inject(1) {|sum, field| sum + field.length}
    end
    
    def test_field_attributes
      @dbf.fields.each do |field|
        assert_kind_of DBF::Field, field
        assert field.name.is_a?(String) && !field.name.empty?
        assert %w(C N L D M F B G P Y T I V X @ O +).include?(field.type)
        assert_kind_of Fixnum, field.length
        assert field.length > 0
        assert_kind_of Fixnum, field.decimal
      end
    end
    
    def test_random_records
      10.times do
        record_num = rand(@controls[:record_count])
        assert_equal @dbf.records[record_num], @dbf.record(record_num)
      end
    end
    
    def test_character_fields
      @controls[:testable_character_field_names].each do |name|
        assert(@dbf.records.any? {|record| record[name].is_a?(String)})
      end
    end
    
    def test_date_fields
      @controls[:testable_date_field_names].each do |name|
        assert(@dbf.records.any? {|record| record[name].is_a?(Date) || record[name].is_a?(Time)})
      end
    end
    
    def test_integer_numeric_fields
      @controls[:testable_integer_field_names].each do |name|
        assert(@dbf.records.any? {|record| record[name].is_a?(Fixnum)})
      end
    end
    
    def test_float_numeric_fields
      @controls[:testable_float_field_names].each do |name|
        assert(@dbf.records.any? {|record| record[name].is_a?(Float)})
      end
    end
    
    def test_logical_fields
      # need a test database that has a logical field
    end

    def test_memo_fields
      @controls[:testable_memo_field_names].each do |name|
        assert(@dbf.records.any? {|record| record[name].is_a?(String)}, "expected a String")
        assert(@dbf.records.any? {|record| record[name].is_a?(String) && record[name].size > 1})
      end
    end
  
  end
  
end