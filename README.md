# DBF
[![Version](http://img.shields.io/gem/v/dbf.svg?style=flat)](https://rubygems.org/gems/dbf)
[![Build Status](http://img.shields.io/travis/infused/dbf/master.svg?style=flat)](http://travis-ci.org/infused/dbf)
[![Code Quality](http://img.shields.io/codeclimate/github/infused/dbf.svg?style=flat)](https://codeclimate.com/github/infused/dbf)
[![Test Coverage](http://img.shields.io/codeclimate/coverage/github/infused/dbf.svg?style=flat)](https://codeclimate.com/github/infused/dbf)
[![Dependency Status](http://img.shields.io/gemnasium/infused/dbf.svg?style=flat)](https://gemnasium.com/infused/dbf)
[![Total Downloads](https://img.shields.io/gem/dt/dbf.svg)](https://rubygems.org/gems/dbf/)

DBF is a small fast library for reading dBase, xBase, Clipper and FoxPro
database files

* Project page: <http://github.com/infused/dbf>
* API Documentation: <http://rubydoc.info/github/infused/dbf/>
* Report bugs: <http://github.com/infused/dbf/issues>
* Questions: Email <mailto:keithm@infused.org> and put DBF somewhere in the
  subject line
* Change log: <https://github.com/infused/dbf/blob/master/CHANGELOG.md>

NOTE: beginning with version 3 we have dropped support for Ruby 1.8 and 1.9. If you need support for older Rubies, please use 2.0.x (https://github.com/infused/dbf/tree/2_stable)

## Compatibility

DBF is tested to work with the following versions of Ruby:

* MRI Ruby 2.0.x, 2.1.x, 2.2.x, 2.3.x
* JRuby head

## Installation

Install the gem manually:

```
gem install dbf
```

Or add to your Gemfile:

```ruby
gem 'dbf'
```

## Basic Usage

Open a DBF file using a path:

```ruby
require 'dbf'
widgets = DBF::Table.new("widgets.dbf")
```

Open a DBF file using an IO object:

```ruby
data = File.open('widgets.dbf')
widgets = DBF::Table.new(data)
```

Open a DBF by passing in raw data (wrap the raw data with a StringIO):

```ruby
widgets = DBF::Table.new(StringIO.new('raw binary data'))
```

Enumerate all records

```ruby
widgets.each do |record|
  puts record.name
  puts record.email
end
```

Find a single record

```ruby
widget = widgets.find(6)
```

Note that find() will return nil if the requested record has been deleted
and not yet pruned from the database.

The value for a attribute can be accessed via element reference in one of three
ways

```ruby
widget["SlotNumber"]   # original field name in dbf file
widget['slot_number']  # underscored field name string
widget[:slot_number]   # underscored field name symbol
```

Attributes can also be accessed as method using the underscored field name

```ruby
widget.slot_number
```

Get a hash of all attributes. The keys are the original column names.

```ruby
widget.attributes
# => {"Name" => "Thing1", "SlotNumber" => 1}
```

Search for records using a simple hash format. Multiple search criteria are
ANDed. Use the block form if the resulting recordset could be large, otherwise
all records will be loaded into memory.

```ruby
# find all records with slot_number equal to s42
widgets.find(:all, slot_number: 's42') do |widget|
  # the record will be nil if deleted, but not yet pruned from the database
  if widget
    puts widget.serial_number
  end
end

# find the first record with slot_number equal to s42
widgets.find :first, slot_number: 's42'

# find record number 10
widgets.find(10)
```

## Enumeration

DBF::Table is a Ruby Enumerable. This means you can use any Enumerable method.
This means that you get a bunch of traversal, searching and sorting methods
for free. For example, let's get only records created before January 1st, 2015:

```ruby
widgets.select { |w| w.created_date < Date.new(2015, 1, 1) }
```

Or custom sorting:

```ruby
widgets.sort_by { |w| w.created_date }
```


## Encodings (Code Pages)

dBase supports encoding non-english characters in different formats.
Unfortunately, the format used is not always set, so you may have to specify it
manually. For example, you have a DBF file from Russia and you are getting bad
data. Try using the 'Russion OEM' encoding:

```ruby
table = DBF::Table.new('dbf/books.dbf', nil, 'cp866')
```

See
[doc/supported_encodings.csv](docs/supported_encodings.csv)
for a full list of supported encodings.

## Migrating to ActiveRecord

An example of migrating a DBF book table to ActiveRecord using a migration:

```ruby
require 'dbf'

class Book < ActiveRecord::Base; end

class CreateBooks < ActiveRecord::Migration
  def self.up
    table = DBF::Table.new('db/dbf/books.dbf')
    eval(table.schema)

    Book.reset_column_information
    table.each do |record|
      Book.create(title: record.title, author: record.author)
    end
  end

  def self.down
    drop_table :books
  end
end
```

If you have initalized the DBF::Table with raw data, you will need to set the
table name manually with:

```ruby
table.name = 'my_table_name'
```

## Migrating to Sequel

An example of migrating a DBF book table to Sequel using a migration:

```ruby
require 'dbf'

class Book < Sequel::Model; end

Sequel.migration do
  up do
    table = DBF::Table.new('db/dbf/books.dbf')
    eval(table.schema(:sequel, true)) # passing true to limit output to create_table() only

    Book.reset_column_information
    table.each do |record|
      Book.create(title: record.title, author: record.author)
    end
  end

  down do
    drop_table(:books)
  end
end
```

If you have initalized the DBF::Table with raw data, you will need to set the
table name manually with:

```ruby
table.name = 'my_table_name'
```

## Command-line utility

A small command-line utility called dbf is installed along with the gem.

    $ dbf -h
    usage: dbf [-h|-s|-a] filename
      -h = print this message
      -v = print the version number
      -s = print summary information
      -a = create an ActiveRecord::Schema
      -r = create a Sequel Migration
      -c = create a csv file

Create an executable ActiveRecord schema:

    dbf -a books.dbf > books_schema.rb

Create an executable Sequel schema:

    dbf -r books.dbf > migrate/001_create_books.rb

Dump all records to a CSV file:

    dbf -c books.dbf > books.csv

## Reading a Visual Foxpro database (v8, v9)

A special Database::Foxpro class is available to read Visual Foxpro container files (.dbc-files). When using this class,
long field names are supported and tables can be referenced without using names.

```ruby
require 'dbf'

contacts = DBF::Database::Foxpro.new('contactdatabase.dbc').contacts
my_contact = contacts.record(1).spouses_interests
```


## dBase version compatibility

The basic dBase data types are generally supported well. Support for the
advanced data types in dbase V and FoxPro are still experimental or not
supported. If you have insight into how any of the unsupported data types are
implemented, please give me a shout. FoxBase/dBase II files are not supported
at this time.

See
[doc/supported_types.markdown](docs/supported_types.markdown)
for a full list of supported column types.

## Limitations

* DBF is read-only
* Index files are not utilized

## License

Copyright (c) 2006-2016 Keith Morrison <<keithm@infused.org>>

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
