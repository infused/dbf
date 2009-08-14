require 'hoe'
require 'spec/rake/spectask'

PKG_NAME = "dbf"
PKG_VERSION = "1.0.9"
PKG_FILE_NAME = "#{PKG_NAME}-#{PKG_VERSION}"

Hoe.spec PKG_NAME do |s|
  s.version = PKG_VERSION
  s.rubyforge_name = PKG_NAME
  s.author = "Keith Morrison"
  s.email = "keithm@infused.org"
  s.summary = "A small fast library for reading dBase, xBase, Clipper and FoxPro database files."
  s.description = s.paragraphs_of("README.txt", 1..3).join("\n\n")
  s.changes = s.paragraphs_of("History.txt", 0..1).join("\n\n")
  s.url = "http://github.com/infused/dm-dbf/tree/master"
  s.need_tar = true
  s.need_zip = true
  s.extra_deps << ['activesupport', '>= 2.1.0']
  s.extra_deps << ['fastercsv', '>= 1.4.0']
end

task :default => :spec

desc "Run specs"
Spec::Rake::SpecTask.new :spec do |t|
  t.spec_files = FileList['spec/**/*spec.rb']
end

desc "Run spec docs"
Spec::Rake::SpecTask.new :specdoc do |t|
  t.spec_opts = ["-f specdoc"]
  t.spec_files = FileList['spec/**/*spec.rb']
end

desc "Generate gemspec"
task :gemspec do |t|
  `rake debug_gem > dbf.gemspec`
end