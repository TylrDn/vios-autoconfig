#!/usr/bin/env bash
# lib/plan.sh - simple planning and apply helpers
set -euo pipefail
IFS=$'\n\t'
LC_ALL=C
# shellcheck source=./common.sh

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

plan_add() {
  local json="$1"
  [[ -n "${PLAN_PATH}" ]] || die "plan_init not called"
  printf '%s\n' "${json}" >>"${PLAN_PATH}"
}

plan_show() {
  [[ -n "${PLAN_PATH}" ]] || die "plan_init not called"
  cat "${PLAN_PATH}"
}

plan_apply() {
  [[ -n "${PLAN_PATH}" ]] || die "plan_init not called"
  require_cmd jq
  while IFS= read -r line; do
    local action
    action="$(printf '%s' "$line" | jq -r '.action')"
    case "$action" in
      pin-hostkey)
        local host
        host="$(printf '%s' "$line" | jq -r '.host')"
        pin_hostkey "$host"
        ;;
      *)
        log WARN "Unknown action in plan: $action"
        ;;
    esac
  done <"${PLAN_PATH}"
}
