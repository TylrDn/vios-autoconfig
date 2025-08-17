#!/usr/bin/env bash
# lib/parse.sh - YAML parsing helpers using Python (PyYAML)
. "$(dirname "${BASH_SOURCE[0]}")/header.sh"

# Exit codes for yaml_get
readonly YAML_GET_ERR_RUNTIME=1   # unexpected runtime error
readonly YAML_GET_ERR_PARSE=2     # YAML parse error or missing dependency
readonly YAML_GET_ERR_MISSING=3   # requested key not found

# yaml_get <file> <key.path>
yaml_get() {
  require_cmd python3
  local file="$1" key="$2"
  RUNTIME_ERR="$YAML_GET_ERR_RUNTIME" \
  PARSE_ERR="$YAML_GET_ERR_PARSE" \
  MISSING_KEY_ERR="$YAML_GET_ERR_MISSING" \
  python3 - "$file" "$key" <<'PY'
import os, sys, json
runtime_err = int(os.environ["RUNTIME_ERR"])
parse_err = int(os.environ["PARSE_ERR"])
missing_key_err = int(os.environ["MISSING_KEY_ERR"])
try:
    import yaml
except Exception:
    sys.exit(parse_err)  # parse error / missing dependency

try:
    file, key = sys.argv[1], sys.argv[2]
    with open(file) as f:
        data = yaml.safe_load(f)
except yaml.YAMLError:
    sys.exit(parse_err)
except Exception:
    sys.exit(runtime_err)

val = data
for part in key.split('.'):
    if isinstance(val, dict):
        val = val.get(part)
    else:
        val = None
        break
if val is None:
    sys.exit(missing_key_err)
if isinstance(val, (dict, list)):
    print(json.dumps(val))
else:
    print(val)
PY
}
