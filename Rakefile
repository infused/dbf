require 'hoe'
require 'spec/rake/spectask'

PKG_NAME = "dbf"
PKG_VERSION = "0.5.0"
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

Hoe.new PKG_NAME, PKG_VERSION do |p|
  p.rubyforge_name = PKG_NAME
  p.author = "Keith Morrison"
  p.email = "keithm@infused.org"
  p.summary = "A small fast library for reading dBase, xBase, Clipper and FoxPro database files."
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

desc "Run specs"
Spec::Rake::SpecTask.new :spec do |t|
  t.spec_opts = ["-f specdoc"]
  t.spec_files = FileList['spec/**/*spec.rb']
end
