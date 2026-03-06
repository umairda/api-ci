#!/usr/bin/env bash
set -euo pipefail

make coverage

if [[ ! -f health_api.cpp.gcov ]]; then
  echo "gcov output file not found."
  exit 1
fi

coverage_line=$(grep -E "^Lines executed:" health_api.cpp.gcov || true)
if [[ -z "$coverage_line" ]]; then
  echo "Could not parse coverage output."
  exit 1
fi

echo "$coverage_line"
percent=$(echo "$coverage_line" | sed -E 's/Lines executed:([0-9.]+)%.*/\1/')

required=80
awk -v p="$percent" -v r="$required" 'BEGIN { exit (p+0 >= r+0 ? 0 : 1) }'
echo "Coverage gate passed: ${percent}% >= ${required}%"
