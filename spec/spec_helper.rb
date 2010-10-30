$:.unshift(File.dirname(__FILE__) + '/../lib/')
require 'rubygems'
require 'rspec'
require 'dbf'
require 'fileutils'

DB_PATH = File.dirname(__FILE__) + '/fixtures' unless defined?(DB_PATH)

RSpec.configure do |config|
  
end

self.class.send :remove_const, 'Test' if defined? Test