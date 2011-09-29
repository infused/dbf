# encoding: utf-8

require 'rubygems'
require 'bundler/setup';
Bundler.setup(:default, :development)

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new :spec do |t|
  t.rspec_opts = %w(-fs --color)
end

require 'rake'
require 'rdoc/task'
Rake::RDocTask.new { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "DBF - A small fast library for reading dBase, xBase, Clipper and FoxPro database files."
  rdoc.options << '--line-numbers'
  rdoc.template = "#{ENV['template']}.rb" if ENV['template']
  rdoc.rdoc_files.include('README.md', 'docs/supported_types.markdown', 'lib/**/*.rb')
}

task :default => :spec

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -I lib -r dbf.rb"
end

# require 'metric_fu'
# MetricFu::Configuration.run do |config|
#   config.rcov[:test_files] = ['spec/**/*_spec.rb']  
#   config.rcov[:rcov_opts] << "-Ispec"
# end