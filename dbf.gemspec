require_relative 'lib/dbf/version'

Gem::Specification.new do |s|
  s.name = 'dbf'
  s.version = DBF::VERSION
  s.authors = ['Keith Morrison']
  s.email = 'keithm@infused.org'
  s.homepage = 'https://github.com/infused/dbf'
  s.summary = 'Read xBase files'
  s.description = 'A small fast library for reading dBase, xBase, Clipper and FoxPro database files.'
  s.license = 'MIT'
  s.bindir = 'bin'
  s.executables = ['dbf']
  s.files = Dir['README.md', 'CHANGELOG.md', 'LICENSE', '{bin,lib}/**/*', 'dbf.gemspec']
  s.require_paths = ['lib']
  s.required_ruby_version = '>= 3.3.0'
  s.metadata['rubygems_mfa_required'] = 'true'
  s.metadata['source_code_uri'] = 'https://github.com/infused/dbf'
  s.metadata['changelog_uri'] = 'https://github.com/infused/dbf/blob/main/CHANGELOG.md'
  s.add_dependency 'csv'
end
