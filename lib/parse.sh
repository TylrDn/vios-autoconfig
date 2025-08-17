#!/usr/bin/env bash
# lib/parse.sh - YAML parsing helpers using Python (PyYAML)
# Ensures locale-independent parsing and simple key lookup.
set -euo pipefail
IFS=$'\n\t'
LC_ALL=C

# yaml_get <file> <key.path>
yaml_get() {
  require_cmd python3
  local file="$1" key="$2"
  python3 - "$file" "$key" <<'PY'
import sys, yaml, json
file, key = sys.argv[1], sys.argv[2]
with open(file) as f:
    data = yaml.safe_load(f)
val = data
for part in key.split('.'):
    if isinstance(val, dict):
        val = val.get(part)
    else:
        val = None
        break
if val is None:
    sys.exit(1)
if isinstance(val, (dict, list)):
    print(json.dumps(val))
else:
    print(val)
PY
}
