$:.unshift(File.dirname(__FILE__) + "/../lib/")
require 'test/unit'
require 'dbf'
require 'common'

class VisualFoxproReadTest < Test::Unit::TestCase
  include CommonTests::Read
  
  def setup
    @controls = {
      :version => "30",
      :has_memo_file => true,
      :memo_file_format => :fpt,
      :field_count => 145,
      :record_count => 34,
      :record_length => 3907,
      :testable_character_field_names => [],
      :testable_date_field_names => [],
      :testable_integer_field_names => ["IMAGENO"],
      :testable_float_field_names => [],
      :testable_logical_field_names => [],
      :testable_memo_field_names => ["CREDIT"]
    }
    @dbf = DBF::Reader.new(File.join(File.dirname(__FILE__),'databases', 'visual_foxpro.dbf'))
  end
  
end