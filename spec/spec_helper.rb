begin
  require 'codeclimate-test-reporter'
  CodeClimate::TestReporter.start
rescue LoadError
end

require 'dbf'
require 'yaml'
require 'rspec'
require 'fileutils'

RSpec.configure do |config|
  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end

def fixture_path
  @fixture_path ||= File.join(File.dirname(__FILE__), '/fixtures')
end

def fixture(filename)
  File.join(fixture_path, filename)
end
