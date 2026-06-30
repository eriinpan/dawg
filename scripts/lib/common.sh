#!/usr/bin/env bash
# Shared helpers for local meeting-minutes runs.

set -euo pipefail

repo_root() {
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[1]}")" && pwd)"
  cd "${script_dir}/../.." && pwd
}

find_agent_cli() {
  local cmd
  for cmd in agent cursor-agent; do
    if command -v "${cmd}" >/dev/null 2>&1; then
      command -v "${cmd}"
      return 0
    fi
  done
  return 1
}

ensure_log_dir() {
  local root="$1"
  mkdir -p "${root}/logs"
}

timestamp() {
  date +"%Y-%m-%dT%H:%M:%S%z"
}
