# Changelog

## [Unreleased]

### Added

- `DBF::Table.new` accepts any IO-like object responding to `#read` and `#seek` (`File`, `Tempfile`, …) in addition to a path or `StringIO`, matching what the README already documented; IO inputs are switched to binary mode, and memo auto-discovery works from the IO's path when it has one
- `DBF::Error` base class: all library errors (`FileNotFoundError`, `NoColumnsDefined`, `Column::LengthError`, `Column::InvalidNameError`) now inherit from it, so callers can `rescue DBF::Error` to catch anything the library raises
- `Table#filename` now works for any IO input with a path, not only `File`
- `DBF::Table.open`: same arguments as `.new`, but the block form yields the table, closes it when the block returns, and returns the block's value — the same contract as `File.open`
- CI: lint job running RuboCop and Reek on every push and pull request
- CI: test on Windows and macOS (Ruby 3.4) in addition to Linux, since much real-world DBF data originates on Windows/FoxPro systems
- CI: observe-only (non-blocking) test jobs for JRuby, TruffleRuby, and Ruby head
- CI: enforce a 99% minimum test coverage floor via SimpleCov
- Docs site (dbf.infused.org): YARD docs are now built and deployed by CI instead of being committed to the repository; the Pages workflow's deprecated v2/v3 actions (whose artifact backend was shut down in early 2025) are updated to current versions, repairing the broken deploy
- Dependabot updates for GitHub Actions and gems (weekly), a security policy (SECURITY.md) with private vulnerability reporting, and contributor documentation (CONTRIBUTING.md)
- Automated releases: pushing a `vX.Y.Z` tag now builds and publishes the gem to RubyGems.org from CI via Trusted Publishing (OIDC) — no long-lived API key. `bundler/gem_tasks` is loaded in the Rakefile, providing `rake build` / `rake release`. Git tags resume at v5.4.0; versions 4.0.0–5.3.0 were released without tags

### Fixed

- `Table#to_csv(path)` closes the file it opens, so the CSV is fully flushed to disk when the method returns (previously the data could stay buffered until garbage collection)
- Visual FoxPro: a `.dbc` container supplying fewer long names than the table has columns no longer crashes column building; missing long names fall back to the table's own column names. Column rebuilding is also no longer O(n²)
- `Table#schema` validates the format against the documented list up front; a `NoMethodError` raised inside a valid schema generator is no longer misreported as "not a valid schema"
- FoxPro memo files shorter than their 512-byte header no longer crash memo reads (they return nil like other truncations)
- RuboCop config: restore the default `vendor/**/*` exclusion (overriding `Exclude` replaces the defaults), fixing a CI lint crash where RuboCop descended into cached vendored gems and tried to load plugins from their configs
- CLI: close the table when finished, so the DBF file can be deleted or replaced immediately afterwards on Windows (an open handle blocks deletion there)

### Removed

- CodeClimate config and README badges: the service is sunset, and coverage is now enforced directly in CI

### Changed

- Streaming reads: `Table#each` now reads records in 4 MB chunks of whole records instead of loading the entire record section into memory, so enumerating multi-gigabyte files (for example shapefile `.dbf` sidecars) uses bounded memory. On a 190 MB file, peak process memory drops from ~222 MB to ~35 MB with identical results. No API change; all malformed-file bounds are preserved
- Internal: `DBF::RecordContext` is now an immutable `Data` class instead of a `Struct`
- Internal: remove a redundant `Memo::Foxpro#initialize` and the duplicate `Header::HEADER_SIZE` constant (now sourced from `VersionConfig`)
- README: replace the stack of version-support notes with a compatibility table, point API docs at dbf.infused.org, and refer to LICENSE instead of inlining the full MIT text; copyright years updated through 2026
- Gemspec: add `homepage_uri`, `bug_tracker_uri`, `documentation_uri`, and `funding_uri` metadata (shown on the rubygems.org sidebar), and constrain the `csv` runtime dependency to `~> 3.3`
- `DBF::Column::NameError` is renamed to `DBF::Column::InvalidNameError` (it shadowed Ruby's `::NameError` without being one); the old constant remains as a deprecated alias
- Rescues in date/datetime decoding and FoxPro memo reads are narrowed to the specific expected errors, so genuine programmer errors surface instead of silently returning nil
- Declare `reek` and `simplecov` as direct development dependencies instead of relying on rubycritic's transitive dependencies
- Restrict `debug` and `ruby-lsp` to MRI so `bundle install` succeeds on JRuby/TruffleRuby
- Test matrix no longer fails fast, and a Ruby head regression no longer fails the build
- Update pinned `ruby/setup-ruby` action to v1.321.0

## 5.4.0

- CLI: replace terminal control bytes in file-derived output so a crafted DBF cannot emit escape sequences to an interactive terminal; CSV and schema output are only filtered when writing to a terminal, so redirected exports are unchanged
- Security (CWE-248): write binary or invalidly encoded cells in `Table#to_csv` as representable text instead of raising an encoding error
- Security (CWE-248): replace unrepresentable column type bytes so a corrupt descriptor cannot raise when the schema is serialized to JSON
- Security (CWE-248): `Table#record` returns nil when the file ends after the delete flag instead of crashing on a nil record body
- Security (CWE-248): stop column parsing when the file ends mid-descriptor instead of raising `ArgumentError` from a short unpack
- Security (CWE-248): guard FoxPro memo-pointer decoding against a nil value from a truncated record instead of crashing on nil.unpack1
- Security (CWE-248): guard dBase IV memo reads against a nil/short block header instead of crashing on nil.unpack1
- Security (CWE-248): guard dBase III memo reads against a start block past EOF instead of crashing on a nil block
- Security (CWE-248): stop column parsing on a truncated descriptor instead of constructing an invalid column that crashes on a nil length
- Security (CWE-248): decode truncated numeric cells (Currency, AutoIncrement) to blank instead of raising an uncaught `nil` crash
- Security (CWE-248): handle truncated headers and missing column terminators gracefully instead of raising an uncaught `nil` crash during column parsing
- Security (CWE-400): bound FoxPro memo reads by the memo file size so a crafted memo size cannot force a ~4 GiB allocation
- Security (CWE-400): bound dBase IV memo reads by the memo file size so a crafted length field cannot force a ~4 GiB allocation
- Security (CWE-835): bound record iteration by the bytes actually read so a crafted `record_count` (or zero `record_length`) cannot cause an unbounded loop
- Security (CWE-789): bound the record read buffer by the file's actual size so a crafted header cannot force a multi-gigabyte allocation from a tiny file
- Security (CWE-400): resolve FoxPro `.dbc` tables by scanning the directory instead of `Dir.glob`, preventing glob brace-expansion CPU exhaustion from a crafted object name
- Security (CWE-22): confine Visual FoxPro `.dbc` table resolution to the database directory, preventing path traversal via a crafted container object name
- Security (CWE-1236): neutralize spreadsheet formula injection in `Table#to_csv` by prefixing a quote to string cells/headers starting with `= + - @`
- Security (CWE-94): escape table and column names when generating ActiveRecord/Sequel schemas, preventing Ruby code injection from crafted DBF header names
- Add support for 8 more code pages (issue #98): Mazovia cp620 and Kamenický cp895 via vendored translation tables (new DBF::Encoder), plus macRoman, cp1255, cp1256, macCyrillic, macCentEuro and macGreek
- Blank Visual FoxPro "T" (DateTime) columns now return nil instead of a Julian day-0 date
- Blank "F" (Float) columns now return nil instead of 0.0, matching "N" (Number) behavior
- Extract CLI logic into DBF::CLI class (bin/dbf is now a thin shim)
- DBF::Table#to_csv now accepts an IO in addition to a String path
- Fix broken link in README

## 5.2.0

- Drop support for Ruby 3.1 and 3.2

## 5.1.1

- Frozen string literals

## 5.1.0

- Drop support for Ruby 3.0.x

## 5.0.1

- Raise ArgumentError data is not a string or StringIO object

## 5.0.0

- Refactor the Column class to support non-ASCII header names
- Output encoding is now set to UTF-8 if there is no embedded encoding and one is not
  specified during DBF::Table initialization.

## 4.3.2

- Fixes to maintain support for Ruby 3.0.x until it's EOL

## 4.3.1

- Fix bug (since 4.2.0) that caused column names not to be truncated after null character

## 4.3.0

- Drop support for Ruby versions older than 3.0
- Require CSV gem

## 4.2.4

- Exclude unnecessary files from the gem file list

## 4.2.3

- Require MFA to publish gem

## 4.2.2

- Faster CSV generation

## 4.2.1

- Support for dBase IV "04" type files

## 4.2.0

- Initial support for dBase 7 files

## 4.1.6

- Add support for file type 32

## 4.1.5

- Better handling for PIPE errors when using command line utility

## 4.1.4

- Add full support for FoxBase files

## 4.1.3

- Raise DBF::NoColumnsDefined error when attempting to read records if no columns are defined

## 4.1.1

- Add required_ruby_version to gemspec

## 4.1.0

- Return Time instead of DateTime

## 4.0.0

- Drop support for ruby-2.2 and earlier

## 3.1.3

- Ensure malformed dates return nil

## 3.1.2

- Fix incorrect columns list when StringIO and encoding set

## 3.1.1

- Use Date.strptime to parse date fields

## 3.1.0

- Use :binary for binary fields in ActiveRecord schemas

## 3.0.8

- Fix uninitialized constant error under Rails 5

## 3.0.7

- Ignore non-existent records if header record count is incorrect

## 3.0.6

- This version has been yanked from rubygems due to errors

## 3.0.5

- Override table name for schema output

## 3.0.4

- Adds -v command-line option to print version
- Adds -r command-line option to create Sequel migration

## 3.0.3

- Uninitialized (N)umbers should return nil

## 3.0.2
  
- Performance improvements for large files

## 3.0.1

- Support FoxPro (G) general field type
- Fix ruby warnings

## 3.0.0

- Requires Ruby version 2.0 and above
- Support the (G) General Foxpro field type

## 2.0.13

- Support 64-bit currency signed currency values
  (see https://github.com/infused/dbf/pull/71)

## 2.0.12

- Parse (I) values as signed
  (see https://github.com/infused/dbf/pull/70)

## 2.0.11

- Foxpro doubles should always return the full stored precision
  (see https://github.com/infused/dbf/pull/69)

## 2.0.10

- allow 0 length fields, but always return nil as value

## 2.0.9

- fix dBase IV attributes when memo file is missing

## 2.0.8

- fix FoxPro currency fields on some builds of Ruby 1.9.3 and 2.0.0

## 2.0.7

- fix the dbf binary on some linux systems

## 2.0.6

- build_memo returns nil on errors

## 2.0.5

- use correct FoxPro memo block size

## 2.0.4
  
- memo fields return nil if memo file is missing

## 2.0.3

- set encoding if table encoding is nil

## 2.0.2

- Allow overriding the character encoding specified in the file

## 2.0.1

- Add experimental support for character encodings under Ruby 1.8

## 2.0.0

- #44 Require FasterCSV gem on all platforms
- Remove rdoc development dependency
- #42 Fixes encoding of memos
- #43 Improve handling of record attributes

## 1.7.5
  
- fixes FoxPro currency (Y) fields

## 1.7.4
  
- Replace Memo Type with Memo File boolean in command-line utility summary output

## 1.7.3
  
- find_all/find_first should ignore deleted records

## 1.7.2
  
- Fix integer division under Ruby 1.8 when requiring mathn
  standard library (see http://bugs.ruby-lang.org/issues/2121)

## 1.7.1

- Fix Table.FOXPRO_VERSIONS breakage on Ruby 1.8

## 1.7.0

- allow DBF::Table to work with dbf data in memory
- allow DBF::Table#to_csv to write to STDOUT

## 1.6.7

- memo columns return nil when no memo file found

## 1.6.6

- add binary data type support to ActiveRecord schema output

## 1.6.5

- support for visual foxpro double (b) data type

## 1.6.3

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
