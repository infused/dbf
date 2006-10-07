#!/usr/bin/env ruby
require 'benchmark'
$:.unshift(File.dirname(__FILE__) + "/../lib/")
require 'dbf'

iterations = 5000

Benchmark.bm() do |x|
  @dbf = DBF::Reader.new(File.join(File.dirname(__FILE__), '..', 'test', 'databases', 'foxpro.dbf'))
  max = @dbf.record_count + 1
  
  x.report("  Record seek:") { iterations.times { @dbf.record(rand(max)) } }
  x.report("Records array:") { iterations.times { @dbf.records[rand(max)] } }
end