require 'bundler/setup'
Bundler.setup(:default, :development)

require 'bundler/gem_tasks'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new :spec do |t|
  t.rspec_opts = %w[--color]
end

RSpec::Core::RakeTask.new :specdoc do |t|
  t.rspec_opts = %w[-fdocumentation]
end

task default: :spec

desc 'Fuzz the read path with mutated fixtures (FUZZ_TIME seconds per worker, FUZZ_JOBS workers, FUZZ_SEED)'
task :fuzz do
  ruby 'spec/fuzz/fuzz.rb'
end

desc 'Open an irb session preloaded with this library'
task :console do
  sh 'irb -r rubygems -I lib -r dbf.rb'
end
