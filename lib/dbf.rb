require 'date'
gem 'activesupport'
require 'active_support/core_ext/object'
require 'active_support/core_ext/date/conversions'
require 'active_support/core_ext/time/conversions'
require 'active_support/core_ext/date_time/conversions'
require 'active_support/core_ext/string/conversions'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/enumerable'

require 'csv'
if CSV.const_defined? :Reader
  require 'fastercsv'
end

require 'dbf/attributes'
require 'dbf/record'
require 'dbf/column'
require 'dbf/memo'
require 'dbf/table'