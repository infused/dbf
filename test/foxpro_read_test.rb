$:.unshift(File.dirname(__FILE__) + "/../lib/")
require 'test/unit'
require 'dbf'
require 'common'

class FoxproReadTest < Test::Unit::TestCase
  include CommonTests::Read
  
  def setup
    @controls = {
      :version => "f5",
      :has_memo_file => true,
      :memo_file_format => :fpt,
      :field_count => 59,
      :record_count => 975,
      :record_length => 969,
      :testable_character_field_names => ["NOM"],
      :testable_date_field_names => ["DATN"],
      :testable_integer_field_names => ["NF"],
      :testable_float_field_names => [],
      :testable_logical_field_names => [],
      :testable_memo_field_names => ["OBSE"]
    }
    @dbf = DBF::Reader.new "#{File.dirname(__FILE__)}/databases/foxpro.dbf"
  end
  
  # make sure we're grabbing the correct memo
  def test_memo_contents
    assert_equal "jos\202 vicente salvador\r\ncapell\205: salvador vidal\r\nen n\202ixer, les castellers li van fer un pilar i el van entregar al seu pare.", 
      @dbf.records[3]['OBSE']
  end
  
end