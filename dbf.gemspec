(in /Users/keithm/projects/dbf)
Gem::Specification.new do |s|
  s.name = %q{dbf}
  s.version = "1.0.6"

  s.specification_version = 2 if s.respond_to? :specification_version=

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Keith Morrison"]
  s.date = %q{2008-05-01}
  s.default_executable = %q{dbf}
  s.description = %q{DBF is a small fast library for reading dBase, xBase, Clipper and FoxPro database files.  It is written completely in Ruby and has no external dependencies.  Copyright (c) 2006-2007 Keith Morrison <keithm@infused.org, www.infused.org>  * Official project page: http://rubyforge.org/projects/dbf * API Documentation: http://dbf.rubyforge.org/docs * To report bugs: http://www.rubyforge.org/tracker/?group_id=2009 * Questions: Email keithm@infused.org and put DBF somewhere in the subject line}
  s.email = %q{keithm@infused.org}
  s.executables = ["dbf"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt", "README.txt", "spec/fixtures/dbase_83_schema.txt"]
  s.files = ["History.txt", "Manifest.txt", "README.txt", "Rakefile", "benchmarks/performance.rb", "benchmarks/seek_benchmark.rb", "bin/dbf", "lib/dbf.rb", "lib/dbf/column.rb", "lib/dbf/globals.rb", "lib/dbf/record.rb", "lib/dbf/table.rb", "spec/fixtures/dbase_03.dbf", "spec/fixtures/dbase_30.dbf", "spec/fixtures/dbase_30.fpt", "spec/fixtures/dbase_83.dbf", "spec/fixtures/dbase_83.dbt", "spec/fixtures/dbase_83_schema.txt", "spec/fixtures/dbase_8b.dbf", "spec/fixtures/dbase_8b.dbt", "spec/fixtures/dbase_f5.dbf", "spec/fixtures/dbase_f5.fpt", "spec/functional/dbf_shared.rb", "spec/functional/format_03_spec.rb", "spec/functional/format_30_spec.rb", "spec/functional/format_83_spec.rb", "spec/functional/format_8b_spec.rb", "spec/functional/format_f5_spec.rb", "spec/spec_helper.rb", "spec/unit/column_spec.rb", "spec/unit/record_spec.rb", "spec/unit/table_spec.rb"]
  s.has_rdoc = true
  s.homepage = %q{http://dbf.rubyforge.org}
  s.rdoc_options = ["--main", "README.txt"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{dbf}
  s.rubygems_version = %q{1.1.1}
  s.summary = %q{A small fast library for reading dBase, xBase, Clipper and FoxPro database files.}

  s.add_dependency(%q<hoe>, [">= 1.5.1"])
end
