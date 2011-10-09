$:.unshift(File.dirname(__FILE__) + '/../lib/')
require 'dbf'
require 'rspec'

DB_PATH = File.dirname(__FILE__) + '/fixtures' unless defined?(DB_PATH)

RSpec.configure do |config|
  
end
