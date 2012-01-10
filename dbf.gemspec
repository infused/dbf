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
  s.rdoc_options = ['--charset=UTF-8']
  s.extra_rdoc_files = ['README.md', 'CHANGELOG.md', 'MIT-LICENSE']
  s.files = Dir['[A-Z]*', '{bin,docs,lib,spec}/**/*', 'dbf.gemspec']
  s.test_files = Dir.glob('spec/**/*_spec.rb')
  s.require_paths = ['lib']

  s.required_rubygems_version = '>= 1.3.0'
  if RUBY_VERSION.to_f < 1.9
    s.add_dependency 'fastercsv', '~> 1.5.4'
  end
  s.add_development_dependency 'rspec', '~> 2.8.0'
  s.add_development_dependency 'rake', '~> 0.9.2'
  
  if RUBY_VERSION == RUBY_VERSION.to_f >= 1.9
    s.add_development_dependency 'rdoc', '~> 2.5.0'
  else
    s.add_development_dependency 'rdoc', '~> 3.11'
  end

  # if RUBY_VERSION.to_f >= 1.9
  #   s.add_development_dependency 'ruby-debug19'
  # elsif RUBY_VERSION != '1.8.6'
  #   s.add_development_dependency 'ruby-debug'
  # end
  # s.add_development_dependency 'metric_fu'
end

