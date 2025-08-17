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
  python3 - "$file" "$key" "$YAML_GET_ERR_RUNTIME" "$YAML_GET_ERR_PARSE" "$YAML_GET_ERR_MISSING" <<'PY'
import sys, json
file, key, runtime_err, parse_err, missing_key_err = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4]), int(sys.argv[5])
try:
    import yaml
except Exception:
    sys.exit(parse_err)  # parse error / missing dependency

try:
    with open(file) as f:
        data = yaml.safe_load(f)
except yaml.YAMLError:
    sys.exit(parse_err)
except Exception:
    sys.exit(runtime_err)

# Split key on unescaped dots; "\." denotes a literal dot in the key
parts, buf, esc = [], "", False
for ch in key:
    if esc:
        buf += ch
        esc = False
    elif ch == "\\":
        esc = True
    elif ch == ".":
        parts.append(buf)
        buf = ""
    else:
        buf += ch
parts.append(buf)

val = data
for part in parts:
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
