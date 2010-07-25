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
