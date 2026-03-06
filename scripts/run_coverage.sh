#!/usr/bin/env bash
set -euo pipefail

coverage_output="$(make coverage 2>&1)"
echo "$coverage_output"

coverage_line="$(echo "$coverage_output" | grep -E '^Lines executed:' | tail -n 1 || true)"

if [[ -z "$coverage_line" ]]; then
  echo "Could not parse coverage output."
  exit 1
fi

echo "$coverage_line"
percent=$(echo "$coverage_line" | sed -E 's/Lines executed:([0-9.]+)%.*/\1/')

required=80
awk -v p="$percent" -v r="$required" 'BEGIN { exit (p+0 >= r+0 ? 0 : 1) }'
echo "Coverage gate passed: ${percent}% >= ${required}%"
