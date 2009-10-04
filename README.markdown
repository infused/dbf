# DBF

DBF is a small fast library for reading dBase, xBase, Clipper and FoxPro database files

* Project page: <http://github.com/infused/dbf>
* API Documentation: <http://rdoc.info/projects/infused/dbf>
* Report bugs: <http://github.com/infused/dbf/issues>
* Questions: Email <mailto:keithm@infused.org> and put DBF somewhere in the subject line

## Features

* No external dependencies
* Fields are type cast to the appropriate Ruby types
* Ability to dump the database schema in the portable ActiveRecord::Schema format

## Installation
  
    gem install dbf
  
## Basic Usage

    require 'rubygems'
    require 'dbf'

    table = DBF::Table.new("widgets.dbf")

    # Tables are enumerable
    widget_ids = table.map { |row| row.id }
    abc_names = table.select { |row| row.name =~ /^[a-cA-C]/ }
    sorted = table.sort_by { |row| row.name }

    # Print the 'name' field from record number 4
    puts table.record(4).name

    # Attributes can also be accessed using the column name as a Hash key
    puts table.record(4).attributes["name"]
  
    # Print the 'name' and 'address' fields from each record
    table.records.each do |record|
      puts record.name
      puts record.email
    end

    # Find records
    table.find :all, :first_name => 'Keith'
    table.find :all, :first_name => 'Keith', :last_name => 'Morrison'
    table.find :first, :first_name => 'Keith'
    table.find(10)
  
## Migrating to ActiveRecord

An example of migrating a DBF book table to ActiveRecord using a migration:

    require 'dbf'

    class CreateBooks < ActiveRecord::Migration
      def self.up
        table = DBF::Table.new('db/dbf/books.dbf')
        eval(table.schema)

        table.records.each do |record|
          Book.create(record.attributes)
        end
      end

      def self.down
        drop_table :books
      end
    end
  
## Command-line utility

A small command-line utility called dbf is installed along with the gem.

    $ dbf -h
    usage: dbf [-h|-s|-a] filename
      -h = print this message
      -s = print summary information
      -a = create an ActiveRecord::Schema
  
## Limitations and known bugs
  
* DBF is read-only
* Index files are not used

## License

(The MIT Licence)

Copyright (c) 2006-2009 Keith Morrison <mailto:keithm@infused.org>, <http://www.infused.org>

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
