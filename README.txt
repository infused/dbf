= DBF

DBF is a small fast library for reading dBase, xBase, Clipper and FoxPro database files.  It is written completely in Ruby and has no external dependencies.

Copyright (c) 2006-2007 Keith Morrison <keithm@infused.org, www.infused.org>

* Official project page: http://rubyforge.org/projects/dbf
* API Documentation: http://dbf.rubyforge.org/docs
* To report bugs: http://www.rubyforge.org/tracker/?group_id=2009
* Questions: Email keithm@infused.org and put DBF somewhere in the subject
  line

== Features

* No external dependencies
* Fields are type cast to the appropriate Ruby types
* Date/Time fields are returned as either a Time or Date object.  Date 
  will only be used if the date is out of range for Ruby's built in Time
  class.
* Ability to dump the database schema in the portable ActiveRecord::Schema
  format.

== Installation
  
  gem install dbf
  
== Basic Usage

  require 'rubygems'
  require 'dbf'

  reader = DBF::Reader.new("old_data.dbf")
  
  # Print the 'name' field from record number 4
  puts reader.record(4)['name'] 
  
  # Print the 'name' and 'address' fields from each record
  reader.records.each do |record|
    puts record['name']
    puts record['email']
  end

  # Find records
  reader.find :all, :first_name => 'Keith'
  reader.find :all, :first_name => 'Keith', :last_name => 'Morrison'
  reader.find :first, :first_name => 'Keith'
  reader.find(10)
  
== Dealing with deleted records
xBase database systems do not physically delete records, but merely mark the
records for deletion. The file must be compacted using a special utility to
remove the deleted records.

DBF returns nil for any record that has been marked for deletion, so if the
database file has deleted records, you need to be careful when looping. For
example, the following will fail if it encounters a nil record:

  reader.records.each do |record| puts record['name'] end
  
Therefore, it's a good idea to compact the records array to remove any nil
records before iterating over it:

  reader.records.compact.each do |record|
    puts record['name']
    puts record['email']
  end

== Large databases

DBF::Reader defaults to loading all records into memory. This may not be what
you want, especially if the database is large. To disable this behavior, set
the in_memory option to false during initialization.

  reader = DBF::Reader.new("old_data.dbf", :in_memory => false)

== Command-line utility

A small command-line utility called dbf is installed along with the gem.

  $ dbf -h
  usage: dbf [-h|-s|-a] filename
    -h = print this message
    -s = print summary information
    -a = create an ActiveRecord::Schema
  
== Limitations and known bugs
  
* DBF is read-only at the moment
* Index files are not utilized

== License

(The MIT Licence)

Copyright (c) 2006-2007 Keith Morrison <keithm@infused.org>

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
