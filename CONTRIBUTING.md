# Contributing

Thanks for your interest in improving DBF!

## Setup

```
git clone https://github.com/infused/dbf.git
cd dbf
bundle install
```

## Running the checks

```
bundle exec rake          # test suite (RSpec)
bundle exec rubocop       # lint
bundle exec reek lib bin  # code smells
```

CI runs all three on every pull request, across Linux, Windows, and macOS,
and enforces a minimum test coverage floor — please keep new code covered.

`bundle exec rake fuzz` runs a mutation fuzzer over the fixtures for a minute
(`FUZZ_TIME=600 FUZZ_JOBS=4` for longer). It reports any input that raises
something other than `DBF::Error`, takes over a second, or allocates far more
than its size, and writes a minimised reproducer for each to `tmp/fuzz/`. See
`spec/fuzz/fuzz.rb` for options. CI runs it too, but its failures do not block
a merge.

## Pull requests

- Keep each PR to one logical change.
- Add or update specs for any behavior change. Binary-format edge cases
  (truncated files, crafted headers) belong in `spec/dbf/security_spec.rb`.
- Add a line to the `[Unreleased]` section of `CHANGELOG.md`.
- Fixture files for new dBase/FoxPro variants are welcome — small,
  anonymized samples only.

## Reporting issues

For suspected security vulnerabilities, see [SECURITY.md](SECURITY.md) —
please do not open a public issue.
