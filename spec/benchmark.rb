# frozen_string_literal: true

require 'benchmark'
require 'json'
require 'tempfile'
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'dbf'

FIXTURES = File.expand_path('fixtures', __dir__)
WARMUP = 2
ITERATIONS = 10

def count_allocations
  GC.disable
  before = ObjectSpace.count_objects
  yield
  after = ObjectSpace.count_objects
  GC.enable
  after[:TOTAL] - before[:TOTAL]
end

def bench(name, warmup: WARMUP, iterations: ITERATIONS, &block)
  warmup.times(&block)
  GC.compact if GC.respond_to?(:compact)

  times = iterations.times.map do
    GC.start
    t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    yield
    Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0
  end

  allocations = count_allocations(&block)

  median = times.sort[times.length / 2]
  {
    name: name,
    median_ms: (median * 1000).round(3),
    min_ms: (times.min * 1000).round(3),
    max_ms: (times.max * 1000).round(3),
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
