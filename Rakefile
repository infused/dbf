# encoding: utf-8

require 'rubygems'
require 'bundler/setup';
Bundler.setup(:default, :development)

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new :spec do |t|
  t.rspec_opts = %w(--color)
end

RSpec::Core::RakeTask.new :specdoc do |t|
  t.rspec_opts = %w(-fl)
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

namespace :test do
  task :rubies do
    require File.expand_path('spec/rvm_ruby_runner', File.dirname(__FILE__))
    
    current_rvm = `rvm info`.lines.to_a[1]
  
    rubies = %w(
      ree-1.8.6
      ree-1.8.7
      jruby-1.6.2
      jruby-1.6.3
      jruby-1.6.4
      jruby-1.6.5
      ruby-1.8.6 
      ruby-1.8.7
      ruby-1.9.1
      ruby-1.9.2
      ruby-1.9.3
    )
    rubies.each do |version|
      puts RvmRubyRunner.run(version)
    end
  
    `rvm use #{current_rvm}`
  end
end