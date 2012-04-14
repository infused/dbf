require 'date'

require 'csv'
if CSV.const_defined? :Reader
  require 'fastercsv'
end

require 'dbf/record'
require 'dbf/column/base'
require 'dbf/column/dbase'
require 'dbf/column/foxpro'
require 'dbf/table'
require 'dbf/table/encodings'
require 'dbf/memo/base'
require 'dbf/memo/dbase3'
require 'dbf/memo/dbase4'
require 'dbf/memo/foxpro'
