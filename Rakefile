PROJECT_ROOT = File.expand_path(File.dirname(__FILE__))
$: << File.join(PROJECT_ROOT, 'lib')

require 'rubygems'
require 'jeweler'
require 'spec/rake/spectask'
require 'metric_fu'

Jeweler::Tasks.new do |s|
  s.name = 'dbf'
  s.description = 'A small fast library for reading dBase, xBase, Clipper and FoxPro database files.'
  s.summary = 'Read xBase files'
  s.platform = Gem::Platform::RUBY
  s.authors = ['Keith Morrison']
  s.email = 'keithm@infused.org'
  s.add_dependency('activesupport', ['>= 2.1.0'])
  s.add_dependency('fastercsv', ['>= 1.4.0'])
  s.homepage = 'http://github.com/infused/dbf'
end

Jeweler::GemcutterTasks.new

task :default => :spec

desc "Run specs"
Spec::Rake::SpecTask.new :spec do |t|
  t.spec_files = FileList['spec/**/*spec.rb']
end

desc "Run spec docs"
Spec::Rake::SpecTask.new :specdoc do |t|
  t.spec_opts = ["-f specdoc"]
  t.spec_files = FileList['spec/**/*spec.rb']
end
