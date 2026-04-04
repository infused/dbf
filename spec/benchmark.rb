# frozen_string_literal: true

require 'benchmark'
require 'json'
require 'tempfile'
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'dbf'

FIXTURES = File.expand_path('fixtures', __dir__)
WARMUP = 2
ITERATIONS = 10
CLOCK_TYPE = Process::CLOCK_MONOTONIC

def count_allocations
  GC.disable
  before_count = ObjectSpace.count_objects[:TOTAL]
  yield
  after_count = ObjectSpace.count_objects[:TOTAL]
  GC.enable
  after_count - before_count
end

def measure_time
  GC.start
  start_time = Process.clock_gettime(CLOCK_TYPE)
  yield
  Process.clock_gettime(CLOCK_TYPE) - start_time
end

def bench(name, warmup: WARMUP, iterations: ITERATIONS, &block)
  warmup.times(&block)
  GC.compact

  durations = iterations.times.map { measure_time(&block) }
  allocations = count_allocations(&block)
  min, max = durations.minmax

  {
    name: name,
    median_ms: (durations.sort[durations.length / 2] * 1000).round(3),
    min_ms: (min * 1000).round(3),
    max_ms: (max * 1000).round(3),
    allocations: allocations
  }
end

results = []

# Benchmark 1: Open and read all records from a large file with memo
results << bench('read_all_f5') do
  table = DBF::Table.new("#{FIXTURES}/dbase_f5.dbf")
  table.each { |r| r&.to_a }
  table.close
end

# Benchmark 2: Open and read all records from dbase_83 (with memo)
results << bench('read_all_83') do
  table = DBF::Table.new("#{FIXTURES}/dbase_83.dbf")
  table.each { |r| r&.to_a }
  table.close
end

# Benchmark 3: Open and read all records from dbase_03 (no memo, small)
results << bench('read_all_03') do
  table = DBF::Table.new("#{FIXTURES}/dbase_03.dbf")
  table.each { |r| r&.to_a }
  table.close
end

# Benchmark 4: Column parsing only (open + columns, no record iteration)
results << bench('columns_only_f5') do
  table = DBF::Table.new("#{FIXTURES}/dbase_f5.dbf")
  table.columns
  table.close
end

# Benchmark 5: CSV export
results << bench('csv_export_83') do
  Tempfile.create('bench') do |f|
    table = DBF::Table.new("#{FIXTURES}/dbase_83.dbf")
    table.to_csv(f.path)
    table.close
  end
end

# Benchmark 6: find with conditions
results << bench('find_first_03') do
  table = DBF::Table.new("#{FIXTURES}/dbase_03.dbf")
  table.find(:first, {})
  table.close
end

# Benchmark 7: Record attribute access
results << bench('attributes_83') do
  table = DBF::Table.new("#{FIXTURES}/dbase_83.dbf")
  table.each { |r| r&.attributes }
  table.close
end

# Summary
total_ms = results.sum { |r| r[:median_ms] }
total_allocs = results.sum { |r| r[:allocations] }

output = {
  ruby_version: RUBY_VERSION,
  timestamp: Time.now.iso8601,
  total_median_ms: total_ms.round(3),
  total_allocations: total_allocs,
  benchmarks: results
}

puts JSON.pretty_generate(output)
