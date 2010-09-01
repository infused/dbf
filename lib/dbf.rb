require 'date'
gem 'activesupport', '>=2.3.5'
require 'active_support'
require 'active_support/core_ext'

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
require 'dbf/table'