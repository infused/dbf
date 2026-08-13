# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| 5.x     | :white_check_mark: |
| < 5.0   | :x:                |

## Reporting a Vulnerability

Please report suspected vulnerabilities privately via
[GitHub's private vulnerability reporting](https://github.com/infused/dbf/security/advisories/new)
rather than opening a public issue.

You can expect an initial response within a week. If the report is accepted, a
fix will be developed privately and released with credit to the reporter
(unless you prefer otherwise).

## Scope

DBF parses binary files that may come from untrusted sources. Crashes,
unbounded memory allocation, path traversal, or code injection reachable
through a crafted `.dbf`/`.dbt`/`.fpt`/`.dbc` file are all considered security
issues. The test suite contains an extensive set of malformed-file regression
specs (`spec/dbf/security_spec.rb`); fixes are expected to add to it.
