$:.unshift(File.dirname(__FILE__) + '/../lib/')
require 'dbf'
require 'rspec'

DB_PATH = File.dirname(__FILE__) + '/fixtures' unless defined?(DB_PATH)

if RUBY_VERSION == "1.8.6"
  # warn 'ruby-1.8.6: defining Array#reduce as alias of Array#inject'
  class Array
    alias_method :reduce, :inject
  end
end

RSpec.configure do |config|
  def ruby_supports_mathn?
    begin
      require 'mathn'
    rescue UnsupportedLibraryError
      false
    end
  end
end
