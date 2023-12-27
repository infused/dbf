# DBF

[![Version](https://img.shields.io/gem/v/dbf.svg?style=flat)](https://rubygems.org/gems/dbf)
[![Build Status](https://github.com/infused/dbf/actions/workflows/build.yml/badge.svg)](https://github.com/infused/dbf/actions/workflows/build.yml)
[![Code Quality](https://img.shields.io/codeclimate/maintainability/infused/dbf.svg?style=flat)](https://codeclimate.com/github/infused/dbf)
[![Code Coverage](https://img.shields.io/codeclimate/c/infused/dbf.svg?style=flat)](https://codeclimate.com/github/infused/dbf)
[![Total Downloads](https://img.shields.io/gem/dt/dbf.svg)](https://rubygems.org/gems/dbf/)
[![License](https://img.shields.io/github/license/infused/dbf.svg)](https://github.com/infused/dbf)

DBF is a small, fast Ruby library for reading dBase, xBase, Clipper, and FoxPro database files.

* Project page: <https://github.com/infused/dbf>
* API Documentation: <https://rubydoc.info/github/infused/dbf>
* Report bugs: <https://github.com/infused/dbf/issues>
* Questions: Email <mailto:keithm@infused.org> and put DBF somewhere in the
  subject line
* Change log: <https://github.com/infused/dbf/blob/master/CHANGELOG.md>

NOTE: 

NOTE: Beginning with version 4, we have dropped support for Ruby 2.0, 2.1, 2.2, and 2.3. If you need support for these older Rubies,
please use 3.0.x (<https://github.com/infused.org/dbf/tree/3_stable>)

NOTE: Beginning with version 3, we have dropped support for Ruby 1.8 and 1.9. If you need support for older Rubies,
please use 2.0.x (<https://github.com/infused/dbf/tree/2_stable>)

## Compatibility

DBF is tested to work with the following versions of Ruby:

* Ruby 3.0.x, 3.1.x, 3.2.x, 3.3.x

## Installation

Install the gem manually:

```ruby
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

Open a DBF by passing in raw data (wrap the raw data with StringIO):

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

The value for an attribute can be accessed via element reference in several
ways.

```ruby
widget.slot_number     # underscored field name as method

widget["SlotNumber"]   # original field name in dbf file
widget['slot_number']  # underscored field name string
widget[:slot_number]   # underscored field name symbol
```

Get a hash of all attributes. The keys are the original column names.

```ruby
widget.attributes
# => {"Name" => "Thing1 | SlotNumber" => 1}
```

Search for records using a simple hash format. Multiple search criteria are
ANDed. Use the block form if the resulting record set is too big. Otherwise, all records are loaded into memory.

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

DBF::Table is a Ruby Enumerable, so you get several traversal, search, and sort methods
for free. For example, let's get only records created before January 1st, 2015:

```ruby
widgets.select { |w| w.created_date < Date.new(2015, 1, 1) }
```

Or custom sorting:

```ruby
widgets.sort_by { |w| w.created_date }
```

## Encodings (Code Pages)

dBase supports encoding non-english characters with different character sets. Unfortunately, the character set used may not be set explicitly. In that case, you will have to specify it manually. For example, if you know the dbf file is encoded with 'Russian OEM':

```ruby
table = DBF::Table.new('dbf/books.dbf', nil, 'cp866')
```

| Code Page | Encoding | Description |
| --------- | -------- | ----------- |
| 01 | cp437 | U.S. MS–DOS |
| 02 | cp850 | International MS–DOS |
| 03 | cp1252 | Windows ANSI |
| 08 | cp865 | Danish OEM |
| 09 | cp437 | Dutch OEM |
| 0a | cp850 | Dutch OEM* |
| 0b | cp437 | Finnish OEM |
| 0d | cp437 | French OEM |
| 0e | cp850 | French OEM* |
| 0f | cp437 | German OEM |
| 10 | cp850 | German OEM* |
| 11 | cp437 | Italian OEM |
| 12 | cp850 | Italian OEM* |
| 13 | cp932 | Japanese Shift-JIS |
| 14 | cp850 | Spanish OEM* |
| 15 | cp437 | Swedish OEM |
| 16 | cp850 | Swedish OEM* |
| 17 | cp865 | Norwegian OEM |
| 18 | cp437 | Spanish OEM |
| 19 | cp437 | English OEM (Britain) |
| 1a | cp850 | English OEM (Britain)* |
| 1b | cp437 | English OEM (U.S.) |
| 1c | cp863 | French OEM (Canada) |
| 1d | cp850 | French OEM* |
| 1f | cp852 | Czech OEM |
| 22 | cp852 | Hungarian OEM |
| 23 | cp852 | Polish OEM |
| 24 | cp860 | Portuguese OEM |
| 25 | cp850 | Portuguese OEM* |
| 26 | cp866 | Russian OEM |
| 37 | cp850 | English OEM (U.S.)* |
| 40 | cp852 | Romanian OEM |
| 4d | cp936 | Chinese GBK (PRC) |
| 4e | cp949 | Korean (ANSI/OEM) |
| 4f | cp950 | Chinese Big5 (Taiwan) |
| 50 | cp874 | Thai (ANSI/OEM) |
| 57 | cp1252 | ANSI |
| 58 | cp1252 | Western European ANSI |
| 59 | cp1252 | Spanish ANSI |
| 64 | cp852 | Eastern European MS–DOS |
| 65 | cp866 | Russian MS–DOS |
| 66 | cp865 | Nordic MS–DOS |
| 67 | cp861 | Icelandic MS–DOS |
| 6a | cp737 | Greek MS–DOS (437G) |
| 6b | cp857 | Turkish MS–DOS |
| 6c | cp863 | French–Canadian MS–DOS |
| 78 | cp950 | Taiwan Big 5 |
| 79 | cp949 | Hangul (Wansung) |
| 7a | cp936 | PRC GBK |
| 7b | cp932 | Japanese Shift-JIS |
| 7c | cp874 | Thai Windows/MS–DOS |
| 86 | cp737 | Greek OEM |
| 87 | cp852 | Slovenian OEM |
| 88 | cp857 | Turkish OEM |
| c8 | cp1250 | Eastern European Windows |
| c9 | cp1251 | Russian Windows |
| ca | cp1254 | Turkish Windows |
| cb | cp1253 | Greek Windows |
| cc | cp1257 | Baltic Windows |

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

If you have initialized the DBF::Table with raw data, you will need to set the
exported table name manually:

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

If you have initialized the DBF::Table with raw data, you will need to set the
exported table name manually:

```ruby
table.name = 'my_table_name'
```

## Command-line utility

A small command-line utility called dbf is installed with the gem.

    $ dbf -h
    usage: dbf [-h|-s|-a] filename
      -h = print this message
      -v = print the version number
      -s = print summary information
      -a = create an ActiveRecord::Schema
      -r = create a Sequel Migration
      -c = export as CSV

Create an executable ActiveRecord schema:

    dbf -a books.dbf > books_schema.rb

Create an executable Sequel schema:

    dbf -r books.dbf > migrate/001_create_books.rb

Dump all records to a CSV file:

    dbf -c books.dbf > books.csv

## Reading a Visual Foxpro database (v8, v9)

A special Database::Foxpro class is available to read Visual Foxpro container
files (file with .dbc extension). When using this class, long field names are supported, and tables can be referenced without using names.

```ruby
require 'dbf'

contacts = DBF::Database::Foxpro.new('contact_database.dbc').contacts
my_contact = contacts.record(1).spouses_interests
```

## dBase version compatibility

The basic dBase data types are generally supported well. Support for the
advanced data types in dBase V and FoxPro are still experimental or not
supported. If you have insight into how any of the unsupported data types are
implemented, please open an issue on Github. FoxBase/dBase II files are not supported
at this time.

### Supported data types by dBase version

| Version | Description                                         | C | N | L | D | M | F | B | G | P | Y | T | I | V | X | @ | O | + |
|---------|-----------------------------------------------------|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 02      | FoxBase                                             | Y | Y | Y | Y | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 03      | dBase III without memo file                         | Y | Y | Y | Y | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 04      | dBase IV without memo file                          | Y | Y | Y | Y | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 05      | dBase V without memo file                           | Y | Y | Y | Y | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 07      | Visual Objects 1.x                                  | Y | Y | Y | Y | - | - | - | - | - | - | - | - | - | - | - | - | - |
| 30      | Visual FoxPro                                       | Y | Y | Y | Y | Y | Y | Y | Y | N | Y | N | Y | N | N | N | N | - |
| 31      | Visual FoxPro with AutoIncrement                    | Y | Y | Y | Y | Y | Y | Y | Y | N | Y | N | Y | N | N | N | N | N |
| 32      | Visual FoxPro with field type Varchar or Varbinary  | Y | Y | Y | Y | Y | Y | Y | Y | N | Y | N | Y | N | N | N | N | N |
| 7b      | dBase IV with memo file                             | Y | Y | Y | Y | Y | Y | - | - | - | - | - | - | - | - | - | - | - |
| 83      | dBase III with memo file                            | Y | Y | Y | Y | Y | - | - | - | - | - | - | - | - | - | - | - | - |
| 87      | Visual Objects 1.x with memo file                   | Y | Y | Y | Y | Y | - | - | - | - | - | - | - | - | - | - | - | - |
| 8b      | dBase IV with memo file                             | Y | Y | Y | Y | Y | - | - | - | - | - | - | - | - | N | - | - | - |
| 8e      | dBase IV with SQL table                             | Y | Y | Y | Y | Y | - | - | - | - | - | - | - | - | N | - | - | - |
| f5      | FoxPro with memo file                               | Y | Y | Y | Y | Y | Y | Y | Y | N | Y | N | Y | N | N | N | N | N |
| fb      | FoxPro without memo file                            | Y | Y | Y | Y | - | Y | Y | Y | N | Y | N | Y | N | N | N | N | N |

Data type descriptions

* C = Character
* N = Number
* L = Logical
* D = Date
* M = Memo
* F = Float
* B = Binary
* G = General
* P = Picture
* Y = Currency
* T = DateTime
* I = Integer
* V = VariField
* X = SQL compat
* @ = Timestamp
* O = Double
* + = Autoincrement

## Limitations

* DBF is read-only
* Index files are not utilized

## License

Copyright (c) 2006-2024 Keith Morrison <<keithm@infused.org>>

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
