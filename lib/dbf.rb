require 'date'
gem 'activesupport'
require 'active_support/core_ext/object'
require 'active_support/core_ext/date/conversions'
require 'active_support/core_ext/time/conversions'
require 'active_support/core_ext/date_time/conversions'
require 'active_support/core_ext/string/conversions'
require 'active_support/core_ext/module/delegation'
require 'active_support/core_ext/string/inflections'

if RUBY_VERSION > '1.9'    
 require 'csv'  
 unless defined? FCSV
   class Object  
     FCSV = CSV 
     alias_method :FCSV, :CSV
   end  
 end
else
 require 'fastercsv'
end

require 'dbf/attributes'
require 'dbf/record'
require 'dbf/column'
require 'dbf/memo'
require 'dbf/table'