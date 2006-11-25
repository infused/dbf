require 'rubygems'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/gempackagetask'
Gem::manage_gems

PKG_NAME = "dbf"
PKG_VERSION = "0.4.1"
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

spec = Gem::Specification.new do |s|
  s.name = PKG_NAME
  s.version = PKG_VERSION
  s.author = "Keith Morrison"
  s.email = "keithm@infused.org"
  s.homepage = "http://www.infused.org"
  s.platform = Gem::Platform::RUBY
  s.summary = "A library for reading dBase (or xBase, Clipper, Foxpro, etc) database files"
  s.files = FileList["{lib,test}/**/*"].to_a
  s.require_path = "lib"
  s.has_rdoc = true
end

desc 'Build Gem'
Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

desc 'Run tests'
task :default => :test

desc 'Run tests'
Rake::TestTask.new :test do |t|
  t.libs << "test"
  t.pattern = 'test/*_test.rb'
  t.verbose = true
end
