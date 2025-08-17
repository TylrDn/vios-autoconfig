#!/usr/bin/env bash
# lib/parse.sh - YAML parsing helpers using Python (PyYAML)
. "$(dirname "${BASH_SOURCE[0]}")/header.sh"

# yaml_get <file> <key.path>
yaml_get() {
  require_cmd python3
  local file="$1" key="$2"
  python3 - "$file" "$key" <<'PY'
import sys, json
try:
    import yaml
except Exception:
    sys.exit(2)  # parse error / missing dependency

MISSING_KEY_EXIT = 3
RUNTIME_ERR_EXIT = 1
PARSE_ERR_EXIT = 2

try:
    file, key = sys.argv[1], sys.argv[2]
    with open(file) as f:
        data = yaml.safe_load(f)
except yaml.YAMLError:
    sys.exit(PARSE_ERR_EXIT)
except Exception:
    sys.exit(RUNTIME_ERR_EXIT)

val = data
for part in key.split('.'):
    if isinstance(val, dict):
        val = val.get(part)
    else:
        val = None
        break
if val is None:
    sys.exit(MISSING_KEY_EXIT)
if isinstance(val, (dict, list)):
    print(json.dumps(val))
else:
    print(val)
PY
}
