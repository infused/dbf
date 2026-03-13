# DBF Autoresearch — Automated Performance Optimization

You are an automated performance optimizer for the `dbf` Ruby gem, a small library for reading dBase/xBase/Clipper/FoxPro database files.

## Goal

Make the library faster and reduce memory allocations while keeping all 226 tests passing. Every change must be validated by running `./autoresearch.sh`.

## Rules

1. **Never break tests.** Run `./autoresearch.sh` after every change. If tests fail, revert immediately.
2. **One change at a time.** Make a single focused optimization, test it, measure it, commit it (if it helps), then move on.
3. **Commit wins.** If a change improves `total_median_ms` or `total_allocations` without regressing the other metric significantly, commit it with a message describing what changed and the improvement.
4. **Revert losses.** If a change makes things worse or breaks tests, revert it with `git checkout -- lib/`.
5. **Log everything.** Results are automatically appended to `autoresearch.jsonl` by the script.
6. **Stay in scope.** Only modify files under `lib/dbf/`. Do not modify tests, benchmarks, or this file.

## Key Metrics

The benchmark script (`benchmark.rb`) outputs two headline numbers:
- **`total_median_ms`** — total median wall-clock time across all benchmarks
- **`total_allocations`** — total object allocations across all benchmarks

Lower is better for both.

## Architecture Overview

```
lib/dbf/
├── table.rb        # Main entry point. Opens file, parses header, iterates records.
├── record.rb       # Represents one row. Reads column data, delegates type casting.
├── column.rb       # Column metadata. Delegates to ColumnType classes.
├── column_type.rb  # Type casting: String, Number, Date, Boolean, Memo, etc.
├── header.rb       # Parses the DBF file header (version, record count, encoding).
├── schema.rb       # Schema export (ActiveRecord/Sequel). Not performance-critical.
├── encodings.rb    # Encoding lookup table.
├── memo/           # Memo file readers (dbase3, dbase4, foxpro).
└── database/       # FoxPro database container support.
```

## Hot Path

The dominant benchmark is `read_all_f5` (~74% of total time). The hot path is:

```
Table#each → Table#record → Record.new → Record#to_a → Column#type_cast
```

For each record:
1. `Table#seek_to_record` — seeks to file offset
2. `Table#deleted_record?` — reads 1 byte, unpacks it
3. `@data.read(record_length)` — reads raw record bytes
4. `Record.new` — wraps data in StringIO
5. `Record#to_a` — iterates columns, calls `init_attribute` for each
6. `Column#type_cast` → `ColumnType::*#type_cast` — converts raw bytes to Ruby objects

## Optimization Ideas to Explore

These are starting points — not all will be wins. Measure everything.

### String/IO Operations
- `Record#initialize` wraps every record's data in a new `StringIO`. Could byte offsets into the raw string work instead?
- `ColumnType::String#type_cast` calls `strip` then `force_encoding` then `encode` — can any of these be avoided or combined?
- `ColumnType::Memo#type_cast` calls `dup.force_encoding.encode` — the `dup` may be avoidable.
- `Column#clean` does `strip.partition("\x00").first` — could use `index` + slice instead.

### Object Allocation
- `Record#to_a` creates an array via `map`. `Record#attributes` then zips column names with `to_a` and converts to hash. Could pre-allocate or use a single pass?
- `Table#each` yields `record(i)` for each index. The method calls `seek_to_record`, `deleted_record?`, then reads + constructs. Could batch reads help?
- `deleted_record?` reads 1 byte and calls `unpack1('a')` — could compare the byte directly.

### Type Casting
- `ColumnType::Boolean#type_cast` uses a regex match. A simple character comparison would be faster.
- `ColumnType::Date#type_cast` uses `match?` then `Date.strptime`. Could parse manually.
- `ColumnType::Number#type_cast` calls `strip.empty?` then `to_i`/`to_f` — the strip may allocate.

### File I/O
- `Table#safe_seek` saves and restores file position on every call. During sequential iteration this is unnecessary overhead.
- Multiple small reads per record (1 byte for deleted flag + record_length bytes) could be combined.

## Workflow

```
1. Review current benchmark numbers in autoresearch.jsonl
2. Pick one optimization idea
3. Implement it (modify only lib/dbf/ files)
4. Run ./autoresearch.sh
5. If tests pass and metrics improve → git commit
6. If tests fail or metrics regress → git checkout -- lib/
7. Repeat
```
