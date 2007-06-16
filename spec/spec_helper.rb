$:.unshift(File.dirname(__FILE__) + "/../lib/")
require "rubygems"
require "spec"
require "dbf"

DB_PATH = File.dirname(__FILE__) + '/fixtures' unless defined?(DB_PATH)

Spec::Runner.configure do |config|
  config.mock_with :mocha
end