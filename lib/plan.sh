#!/usr/bin/env bash
# lib/plan.sh - simple planning and apply helpers
. "$(dirname "${BASH_SOURCE[0]}")/header.sh"

PLAN_PATH=""

plan_init() {
  require_cmd uuidgen
  local run_dir="${STATE_DIR}/run"
  local id
  id="$(uuidgen)"
  PLAN_PATH="${run_dir}/${id}/plan.jsonl"
  mkdir -p "${run_dir}/${id}"
  : >"${PLAN_PATH}"
  echo "${PLAN_PATH}"
}

# Validate action JSON line; returns 0 if schema ok
plan_validate() {
  require_cmd jq
  local line="$1"
  printf '%s' "$line" | jq -e 'type == "object" and (.action | type == "string" and length > 0)' >/dev/null
}

plan_add() {
  local json="$1"
  [[ -n "${PLAN_PATH}" ]] || die "plan_init not called"
  require_cmd jq
  if ! printf '%s' "$json" | jq -e . >/dev/null 2>&1; then
    log ERROR "plan_add: invalid JSON"
    return 1
  fi
  if ! plan_validate "$json"; then
    log ERROR "plan_add: JSON missing required fields"
    return 1
  fi
  printf '%s\n' "$json" >>"${PLAN_PATH}"
}

plan_show() {
  [[ -n "${PLAN_PATH}" ]] || die "plan_init not called"
  cat "${PLAN_PATH}"
}

plan_apply() {
  [[ -n "${PLAN_PATH}" ]] || die "plan_init not called"
  require_cmd jq
  local status=0
  while IFS= read -r line; do
    [[ -n "${line//[[:space:]]/}" ]] || continue
    if ! printf '%s' "$line" | jq -e . >/dev/null 2>&1; then
      log WARN "plan_apply: skipping malformed JSON line: $line"
      continue
    fi
    if ! plan_validate "$line"; then
      log WARN "plan_apply: skipping invalid action schema: $line"
      continue
    fi
    local action
    action="$(printf '%s' "$line" | jq -r '.action')"
    case "$action" in
      pin-hostkey)
        local host
        host="$(printf '%s' "$line" | jq -r '.host // empty')"
        if [[ -z "$host" ]]; then
          log ERROR "pin-hostkey missing host"
          status=1
          continue
        fi
        pin_hostkey "$host"
        ;;
      *)
        log ERROR "Unknown action: $action"
        status=1
        # Continue processing to report all unknown actions
        continue
        ;;
    esac
  done <"${PLAN_PATH}"
  return $status
}
