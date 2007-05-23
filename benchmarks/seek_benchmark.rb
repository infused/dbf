#!/usr/bin/env ruby
require 'benchmark'
$:.unshift(File.dirname(__FILE__) + "/../lib/")
require 'dbf'

puts
puts "Runs 5000 random row seeks first using the I/O based record(n) method and then using"
puts "using the array of records."
puts

iterations = 5000
Benchmark.bm(20) do |x|
  @dbf = DBF::Reader.new(File.join(File.dirname(__FILE__), '..', 'test', 'databases', 'foxpro.dbf'))
  max = @dbf.record_count + 1
  
  x.report("I/O based record(n)") { iterations.times { @dbf.record(rand(max)) } }
  x.report("array of records[n]") { iterations.times { @dbf.records[rand(max)] } }
end
