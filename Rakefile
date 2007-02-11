require 'hoe'
# require 'rubygems'
# require 'rake/testtask'
# require 'rake/rdoctask'
# require 'rake/gempackagetask'
# Gem::manage_gems

PKG_NAME = "dbf"
PKG_VERSION = "0.4.3"
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

Hoe.new PKG_NAME, PKG_VERSION do |p|
  p.rubyforge_name = PKG_NAME
  p.author = "Keith Morrison"
  p.email = "keithm@infused.org"
  p.summary = "A library for reading dBase (or xBase, Clipper, Foxpro, etc) database files"
  p.url = "http://dbf.rubyforge.org"
  p.need_tar = true
  p.need_zip = true
end

# spec = Gem::Specification.new do |s|
#   s.name = PKG_NAME
#   s.version = PKG_VERSION
#   s.author = "Keith Morrison"
#   s.email = "keithm@infused.org"
#   s.homepage = "http://www.infused.org"
#   s.platform = Gem::Platform::RUBY
#   s.summary = "A library for reading dBase (or xBase, Clipper, Foxpro, etc) database files"
#   s.files = FileList["{lib,test}/**/*", "doc/README", "Rakefile"].to_a
#   s.require_path = "lib"
#   s.has_rdoc = true
# end
# 
# desc 'Build Gem'
# Rake::GemPackageTask.new(spec) do |pkg|
#   pkg.need_zip = true
#   pkg.need_tar = true
# end

desc 'Run tests'
task :default => :test

desc 'Run tests'
Rake::TestTask.new :test do |t|
  t.libs << "test"
  t.pattern = 'test/*_test.rb'
  t.verbose = true
end

desc "Generate documentation for the application"
Rake::RDocTask.new("rdoc") do |t|
  t.rdoc_dir = 'doc/app'
  t.title    = "Ruby DBF Library"
  t.options << '--line-numbers' << '--inline-source'
  t.rdoc_files.include('doc/README')
  t.rdoc_files.include('lib/**/*.rb')
end

desc "Creates a release tag"
task :create_release_tag do |t|
  puts "Creating svn+ssh://infused@rubyforge.org/var/svn/dbf/tags/RELEASE_#{PKG_VERSION.gsub('.', '_')}"
  `svn copy . svn+ssh://infused@rubyforge.org/var/svn/dbf/tags/RELEASE_#{PKG_VERSION.gsub('.', '_')} -m "Creating RELEASE_#{PKG_VERSION.gsub('.', '_')} tag"`
end

desc "Removes the current release tag"
task :remove_release_tag do |t|
  puts "Removing svn+ssh://infused@rubyforge.org/var/svn/dbf/tags/RELEASE_#{PKG_VERSION.gsub('.', '_')}"
  `svn remove svn+ssh://infused@rubyforge.org/var/svn/dbf/tags/RELEASE_#{PKG_VERSION.gsub('.', '_')} -m "Removing RELEASE_#{PKG_VERSION.gsub('.', '_')} tag"`
end
