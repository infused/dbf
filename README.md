# DBF

DBF is a small fast library for reading dBase, xBase, Clipper and FoxPro
database files

* Project page: <http://github.com/infused/dbf>
* API Documentation: <http://rubydoc.info/github/infused/dbf/frames>
* Report bugs: <http://github.com/infused/dbf/issues>
* Questions: Email <mailto:keithm@infused.org> and put DBF somewhere in the 
  subject line

## Compatibility

DBF works with Ruby 1.8.6, 1.8.7, and 1.9.2

## Installation
  
    gem install dbf
  
## Basic Usage

Load a DBF file:

    require 'dbf'

    widgets = DBF::Table.new("widgets.dbf")

Enumerate all records

    widgets.each do |record|
      puts widget.name
      puts widget.email
    end
    
Load a single record using <tt>find</tt>

    widget.find(6)

Attributes can also be accessed through the attributes hash in original or
underscored form or as an accessor method using the underscored name. (Note
that find() will return nil if the requested record has been deleted and not
yet pruned from the database)

    widget.find(4).attributes["SlotNumber"]
    widget.find(4).attributes["slot_number"]
    widget.find(4).slot_number
  
Search for records using a simple hash format. Multiple search criteria are
ANDed. Use the block form if the resulting recordset could be large, otherwise
all records will be loaded into memory.
    
    # find all records with slot_number equal to s42
    widgets.find(:all, :slot_number => 's42') do |widget|
      # the record will be nil if deleted, but not yet pruned from the database
      if widget
        puts widget.serial_number
      end
    end
    
    # find the first record with slot_number equal to s42
    widgets.find :first, :slot_number => 's42'
    
    # find record number 10
    widgets.find(10)
  
## Migrating to ActiveRecord

An example of migrating a DBF book table to ActiveRecord using a migration:

    require 'dbf'

    class CreateBooks < ActiveRecord::Migration
      def self.up
        table = DBF::Table.new('db/dbf/books.dbf')
        eval(table.schema)

        table.each do |record|
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
      -c = create a csv file
      
## dBase version support

The basic dBase data types are generally supported well. Support for the
advanced data types in dbase V and FoxPro are still experimental or not
supported. If you have insight into how any of the unsupported data types are
implemented, please give me a shout. FoxBase/dBase II files are not supported
at this time.

See
[docs/supported_types.markdown](http://github.com/infused/dbf/blob/master/docs/supported_types.markdown)
for a full list of supported column types.

## Limitations

* DBF is read-only
* Index files are not utilized
* No character set conversions from the code page defined in the dBase file

## License

Copyright (c) 2006-2010 Keith Morrison <keithm@infused.org>

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
