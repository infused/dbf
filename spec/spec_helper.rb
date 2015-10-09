begin
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
rescue LoadError
end

require 'dbf'
require 'yaml'
require 'rspec'
require 'fileutils'

Encoding.default_external = "UTF-8" if defined?(Encoding)

DB_PATH = File.dirname(__FILE__) + '/fixtures' unless defined?(DB_PATH)

RSpec.configure do |config|
  def ruby_supports_mathn?
    begin
      require 'mathn'
    rescue UnsupportedLibraryError
      false
    end
  end
end

def fixture_path(filename)
  "#{DB_PATH}/#{filename}"
end
