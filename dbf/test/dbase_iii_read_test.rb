$:.unshift(File.dirname(__FILE__) + "/../lib/")
require 'test/unit'
require 'dbf'
require 'common'

class DBaseIIIReadTest < Test::Unit::TestCase
  include CommonTests::Read
  
  def setup
    @controls = {
      :version => "03",
      :has_memo_file => false,
      :memo_file_format => nil,
      :field_count => 31,
      :record_count => 14,
      :record_length => 590,
      :testable_character_field_names => ["Shape"],
      :testable_date_field_names => ["Date_Visit"],
      :testable_integer_field_names => ["Filt_Pos"],
      :testable_float_field_names => ["Max_PDOP"],
      :testable_logical_field_names => [],
      :testable_memo_field_names => []
    }
    @dbf = DBF::Reader.new(File.join(File.dirname(__FILE__),'databases', 'dbase_iii.dbf'))
  end
  
end