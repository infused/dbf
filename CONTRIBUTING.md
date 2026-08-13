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
