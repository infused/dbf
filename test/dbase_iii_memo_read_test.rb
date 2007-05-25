$:.unshift(File.dirname(__FILE__) + "/../lib/")
require 'test/unit'
require 'dbf'
require 'common'

class DBaseIIIWithMemoReadTest < Test::Unit::TestCase
  include CommonTests::Read
  
  def setup
    @controls = {
      :version => "83",
      :has_memo_file => true,
      :memo_file_format => :dbt,
      :field_count => 15,
      :record_count => 67,
      :record_length => 805,
      :testable_character_field_names => ["CODE"],
      :testable_date_field_names => [],
      :testable_integer_field_names => ["AGRPCOUNT"],
      :testable_float_field_names => ["PRICE"],
      :testable_logical_field_names => ["TAXABLE"],
      :testable_memo_field_names => ["DESC"]
    }
    @dbf = DBF::Reader.new(File.join(File.dirname(__FILE__),'databases', 'dbase_iii_memo.dbf'))
  end
  
end