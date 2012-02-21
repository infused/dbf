# 1.7.3
  - find_all/find_first should ignore deleted records

# 1.7.2
  - Fix integer division under Ruby 1.8 when requiring mathn
    standard library (see http://bugs.ruby-lang.org/issues/2121)

# 1.7.1
  - Fix Table.FOXPRO_VERSIONS breakage on Ruby 1.8

# 1.7.0
  - allow DBF::Table to work with dbf data in memory
  - allow DBF::Table#to_csv to write to STDOUT

# 1.6.7
  - memo columns return nil when no memo file found

# 1.6.6
  - add binary data type support to ActiveRecord schema output
  
# 1.6.5
  - support for visual foxpro double (b) data type

# 1.6.3
  - Replace invalid chars with 'unicode replacement character' (U+FFFD)

## 1.6.2
  - add Table#filename method
  - Rakefile now loads gems with bundler
  - add Table#supports_encoding?
  - simplify encodings.yml loader
  - add rake and rdoc as development dependencies
  - simplify open_memo file search logic
  - remove unnecessary requires in spec helper
  - fix cli summary

## 1.6.1
  - fix YAML issue when using MRI version > 1.9.1
  - remove Table#seek_to_index and Table#current_record private methods

## 1.6.0
  - remove activesupport gem dependency

## 1.5.0

- Significant internal restructuring and performance improvements. Initial
  testing shows 4x faster performance.

## 1.3.0

- Only load what's needed from activesupport 3.0
- Updatate fastercsv dependency to 1.5.3
- Remove use of 'returning' method
- Remove jeweler in favor of manual gemspec creation
- Move Table#all_values_match? to Record#match?
- Add attr_reader for Record#table
- Use method_defined? instead of respond_to? when defining attribute accessors
- Move memo file check into get_memo_header_info
- Remove unnecessary seek_to_record in Table#each
- Add rake console task
- New Attribute class
- Add a helper method for memo column type
- Move constants into the classes where they are used
- Use bundler

## 1.2.9

- Retain trailing whitespace in memos

## 1.2.8

- Handle missing zeros in date values [#11]

## 1.2.7

- MIT License

## 1.2.6

- Support for Ruby 1.9.2

## 1.2.5

- Remove ruby warning switch
- Requires activesupport version 2.3.5

## 1.2.4

- Add csv output option to dbf command-line utility
- Read Visual FoxPro memos

## 1.2.3

- Small performance gain when unpacking values from the dbf file
- Correctly handle FoxPro's integer data type

## 1.2.2

- Handle invalid date fields

## 1.2.1

- Add support for F field type (Float)

## 1.2.0

- Add Table#to_a

## 1.1.1

- Return invalid DateTime columns as nil

## 1.1.0

- Add support for large table that will not fit into memory

## 1.0.13

- Allow passing an array of ids to find

## 1.0.11

- Attributes are now accessible by original or underscored name

## 1.0.9

- Fix incorrect integer column values (only affecting some dbf files)
- Add CSV export

## 1.0.8

- Truncate column names on NULL
- Fix schema dump for date and datetime columns
- Replace internal helpers with ActiveSupport
- Always underscore attribute names

## 1.0.7

- Remove support for original column names.  All columns names are now downcased/underscored.

## 1.0.6

- DBF::Table now includes the Enumerable module
- Return nil for memo values if the memo file is missing
- Finder conditions now support the original and downcased/underscored column names

## 1.0.5

- Strip non-ascii characters from column names

## 1.0.4

- Underscore column names when dumping schemas (FieldId becomes field_id)

## 1.0.3

- Add support for Visual Foxpro Integer and Datetime columns

## 1.0.2

- Compatibility fix for Visual Foxpro memo files (ignore negative memo index values)

## 1.0.1

- Fixes error when using the command-line interface [#11984]

## 1.0.0

- Renamed classes and refactored code in preparation for adding the
  ability to save records and create/compact databases.
- The Reader class has been renamed to Table
- Attributes are no longer accessed directly from the record.  Use record.attribute['column_name']
  instead, or use the new attribute accessors detailed under Basic Usage.

## 0.5.4

- Ignore deleted records in both memory modes

## 0.5.3

- Added a standalone dbf utility (try dbf -h for help)

## 0.5.0 / 2007-05-25

- New find method
- Full compatibility with the two flavors of memo file
- Two modes of operation:
  - In memory (default): All records are loaded into memory on the first
    request. Records are retrieved from memory for all subsequent requests.
  - File I/O: All records are retrieved from disk on every request
- Improved documentation and more usage examples
