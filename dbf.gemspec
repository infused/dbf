lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift lib unless $LOAD_PATH.include?(lib)
require 'dbf/version'

Gem::Specification.new do |s|
  s.name = 'dbf'
  s.version = DBF::VERSION
  s.authors = ['Keith Morrison']
  s.email = 'keithm@infused.org'
  s.homepage = 'http://github.com/infused/dbf'
  s.summary = 'Read xBase files'
  s.description = 'A small fast library for reading dBase, xBase, Clipper and FoxPro database files.'
  s.license = 'MIT'
  s.bindir = 'bin'
  s.executables = ['dbf']
  s.rdoc_options = ['--charset=UTF-8']
  s.extra_rdoc_files = ['README.md', 'CHANGELOG.md', 'LICENSE']
  s.files = Dir['README.md', 'CHANGELOG.md', 'LICENSE', '{bin,lib,spec}/**/*', 'dbf.gemspec']
  s.require_paths = ['lib']
  s.required_rubygems_version = Gem::Requirement.new('>= 1.3.0')
  s.required_ruby_version = Gem::Requirement.new('>= 3.0.0')
  s.metadata['rubygems_mfa_required'] = 'true'
  s.add_dependency 'csv'
end
