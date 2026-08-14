# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Ractor safety', if: defined?(Ractor) do # rubocop:disable RSpec/DescribeClass
  # Creating a Ractor corrupts Coverage collection on Ruby < 4.0, silently
  # dropping coverage for everything that runs afterward. Examples that spawn
  # Ractors therefore run in a child process so SimpleCov results stay stable.
  def ractor_eval(script)
    program = <<~RUBY
      Warning[:experimental] = false
      require 'dbf'

      # Ractor#take was replaced by #value in newer Rubies
      def await(ractor)
        ractor.respond_to?(:value) ? ractor.value : ractor.take
      end

      result = begin
        #{script}
      end
      puts "RACTOR_RESULT=\#{result.inspect}"
    RUBY

    lib = File.expand_path('../../lib', __dir__)
    output = IO.popen([RbConfig.ruby, '-I', lib, '-'], 'r+', err: [:child, :out]) do |io|
      io.write(program)
      io.close_write
      io.read
    end
    raise "Ractor child process failed:\n#{output}" unless Process.last_status.success?

    output[/^RACTOR_RESULT=(.*)$/, 1]
  end

  it 'exposes only Ractor-shareable constants' do
    constants = [
      DBF::VERSION, DBF::ENCODINGS, DBF::CSV_FORMULA_TRIGGERS,
      DBF::Column::TYPE_CAST_CLASS,
      DBF::Schema::FORMATS, DBF::Schema::OTHER_DATA_TYPES, DBF::Schema::STRING_DATA_FORMATS,
      DBF::CLI::USAGE, DBF::CLI::ACTIONS,
      DBF::CLI::CONTROL_BYTES, DBF::CLI::CONTROL_BYTES_KEEPING_NEWLINES
    ]
    constants += DBF::Encoder.constants.map { |name| DBF::Encoder.const_get(name) }
    constants += DBF::VersionConfig.constants.map { |name| DBF::VersionConfig.const_get(name) }
    constants += DBF::Memo::Base.constants.map { |name| DBF::Memo::Base.const_get(name) }

    constants.each { |constant| expect(Ractor).to be_shareable(constant) }
  end

  it 'reads a table inside a non-main Ractor' do
    result = ractor_eval(<<~RUBY)
      await(Ractor.new(#{fixture('dbase_83.dbf').inspect}) do |path|
        DBF::Table.open(path) do |table|
          [table.record_count, table.record(0).attributes['NAME']]
        end
      end)
    RUBY
    expect(result).to eq [67, 'Assorted Petits Fours'].inspect
  end

  it 'enumerates and exports inside a non-main Ractor' do
    result = ractor_eval(<<~RUBY)
      await(Ractor.new(#{fixture('dbase_83.dbf').inspect}) do |path|
        DBF::Table.open(path) { |table| table.each.count { |record| !record.nil? } }
      end)
    RUBY
    expect(result).to eq '67'
  end
end
