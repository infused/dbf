# encoding: utf-8

require 'rubygems'
require 'rubygems/specification'

def gemspec
  @gemspec ||= begin
    file = File.expand_path('../dbf.gemspec', __FILE__)
    eval(File.read(file), binding, file)
  end
end

begin
  require 'rake/gempackagetask'
rescue LoadError
  task(:gem) { $stderr.puts '`gem install rake` to package gems' }
else
  Rake::GemPackageTask.new(gemspec) do |pkg|
    pkg.gem_spec = gemspec
  end
  task :gem => :gemspec
end

begin
  require 'spec/rake/spectask'
rescue LoadError
  raise 'Run `gem install rspec` to be able to run specs'
else
  task :clear_tmp do
    FileUtils.rm_rf(File.expand_path("../tmp", __FILE__))
  end

  desc "Run specs"
  Spec::Rake::SpecTask.new do |t|
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.spec_opts  = %w(-fs --color)
    t.warning    = true
  end
  task :spec
end

require 'rake'
require 'rake/rdoctask'
Rake::RDocTask.new { |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title    = "DBF - A small fast library for reading dBase, xBase, Clipper and FoxPro database files."
  rdoc.options << '--line-numbers'
  rdoc.template = "#{ENV['template']}.rb" if ENV['template']
  rdoc.rdoc_files.include('README.md', 'docs/supported_types.markdown', 'lib/**/*.rb')
}

desc "install the gem locally"
task :install => :package do
  sh %{gem install pkg/#{gemspec.name}-#{gemspec.version}}
end

desc "validate the gemspec"
task :gemspec do
  gemspec.validate
end

task :package => :gemspec
task :default => :spec

desc "Open an irb session preloaded with this library"
task :console do
  sh "irb -rubygems -I lib -r dbf.rb"
end