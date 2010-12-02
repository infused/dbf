# encoding: utf-8

lib = File.expand_path('../lib/', __FILE__)
$:.unshift lib unless $:.include?(lib)
require 'dbf/version'

Gem::Specification.new do |s|
  s.name = 'dbf'
  s.version = DBF::VERSION
  s.authors = ['Keith Morrison']
  s.email = 'keithm@infused.org'
  s.homepage = 'http://github.com/infused/dbf'
  s.summary = 'Read xBase files'
  s.description = 'A small fast library for reading dBase, xBase, Clipper and FoxPro database files.'
  
  s.executables = ['dbf']
  s.default_executable = 'dbf'
  s.rdoc_options = ['--charset=UTF-8']
  s.extra_rdoc_files = ['README.md', 'CHANGELOG.md']
  s.files = Dir['[A-Z]*', '{bin,docs,lib,spec}/**/*']
  s.test_files = Dir.glob('spec/**/*_spec.rb')
  s.require_paths = ['lib']

  s.required_rubygems_version = '>= 1.3.0'
  s.add_dependency 'activesupport', '~> 3.0.0'
  s.add_dependency 'i18n', '~> 0.4.2'
  s.add_dependency 'fastercsv', '1.5.3'
  s.add_development_dependency 'rspec', '2.2.0'
  s.add_development_dependency 'metric_fu', '2.0.1'
end

