#!/usr/bin/env bash
# Run the meeting-minutes agent locally via Cursor CLI + your Mac MCPs.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROMPT_FILE="${ROOT}/prompts/meeting-minutes.md"
LOG_DIR="${ROOT}/logs"
STAMP="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="${LOG_DIR}/run-${STAMP}.log"

mkdir -p "${LOG_DIR}"

log() {
  printf '[%s] %s\n' "$(date +"%Y-%m-%dT%H:%M:%S%z")" "$*" | tee -a "${LOG_FILE}"
}

if [[ ! -f "${PROMPT_FILE}" ]]; then
  echo "Missing prompt file: ${PROMPT_FILE}" >&2
  exit 1
fi

if ! "${ROOT}/scripts/is-work-hours.sh" 2>/dev/null; then
  log "no-op (outside schedule)"
  exit 0
fi

AGENT=""
for cmd in agent cursor-agent; do
  if command -v "${cmd}" >/dev/null 2>&1; then
    AGENT="${cmd}"
    break
  fi
done

if [[ -z "${AGENT}" ]]; then
  log "ERROR: Cursor CLI not found. Install: curl https://cursor.com/install -fsS | bash"
  log "Then run: agent login"
  exit 1
fi

if [[ ! -f "${HOME}/.cursor/mcp.json" && ! -f "${ROOT}/.cursor/mcp.json" ]]; then
  log "ERROR: No MCP config found."
  log "Copy ${ROOT}/.cursor/mcp.json.example to ~/.cursor/mcp.json and fill in credentials."
  exit 1
fi

PROMPT="$(cat "${PROMPT_FILE}")"

log "Starting meeting-minutes run (${AGENT})"
log "Repo: ${ROOT}"
log "Log: ${LOG_FILE}"

cd "${ROOT}"

set +e
"${AGENT}" -p "${PROMPT}" \
  --approve-mcps \
  --force \
  --output-format text \
  2>&1 | tee -a "${LOG_FILE}"
STATUS=${PIPESTATUS[0]}
set -e

if [[ ${STATUS} -ne 0 ]]; then
  log "ERROR: agent exited with status ${STATUS}"
  log "If MCPs failed, run once interactively: ${ROOT}/scripts/approve-mcps-once.sh"
  exit "${STATUS}"
fi

log "Done."
exit 0
