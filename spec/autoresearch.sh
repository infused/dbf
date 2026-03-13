#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"

echo "=== Running test suite ==="
if ! bundle exec rspec --format progress 2>&1; then
  echo '{"error": "tests failed"}' | tee -a autoresearch.jsonl
  exit 1
fi

echo ""
echo "=== Running benchmarks ==="
result=$(ruby benchmark.rb)
echo "$result"

# Append to results log
echo "$result" | ruby -rjson -e '
  data = JSON.parse($stdin.read)
  entry = {
    timestamp: data["timestamp"],
    ruby_version: data["ruby_version"],
    total_median_ms: data["total_median_ms"],
    total_allocations: data["total_allocations"],
    benchmarks: data["benchmarks"].map { |b| [b["name"], { median_ms: b["median_ms"], allocations: b["allocations"] }] }.to_h
  }
  puts JSON.generate(entry)
' >> autoresearch.jsonl

echo ""
echo "=== Result logged to autoresearch.jsonl ==="
