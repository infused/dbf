require 'hoe'

PKG_NAME = "dbf"
PKG_VERSION = "0.4.5"
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

desc 'Run tests'
task :default => :test

desc 'Run tests'
Rake::TestTask.new :test do |t|
  t.libs << "test"
  t.pattern = 'test/*_test.rb'
  t.verbose = true
end
