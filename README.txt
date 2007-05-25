= DBF

DBF is a small fast library for reading dBase, xBase, Clipper and FoxPro database files.  It is written completely in Ruby and has no external dependencies.

== Features

* No external dependencies
* DB fields are type cast
* Date/Time fields are returned as either a Time or Date object.  Date 
  will only be used if the date is outside the range for Time.

== Installation

  gem install dbf
  
== Usage

  reader = DBF::Reader.new("old_data.dbf")
  
  reader.records.each do |record|
    puts record['name']
    puts record['email']
  end
  
  puts reader.records[4]['name']
  puts reader.record(4)['name']
  
=== A note on record vs. records

DBF::Reader#records is an in-memory array of all rows in the database.  All
rows are loaded the first time that the method is called.  Subsequent calls
retrieve the row from memory.

DBF::Reader#record retrieves the requested row from the database each time
it is called. 

Using records is probably faster most of the time.  Record is more appropriate 
for very large databases where you don't want the whole db loaded into memory.

== Limitations and known bugs
  
* DBF is read-only.  Writing to the database has not yet been implemented.

== License

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
