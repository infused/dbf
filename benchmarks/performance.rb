#!/usr/bin/env ruby

$:.unshift(File.dirname(__FILE__) + "/../lib/")
require 'dbf'
require 'profiler'

dbf = DBF::Reader.new(File.join(File.dirname(__FILE__),'databases', 'foxpro.dbf'))

Profiler__::start_profile

dbf.records

Profiler__::stop_profile
Profiler__::print_profile($stdout)
