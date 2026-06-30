#!/usr/bin/env bash
# One-time interactive run so Cursor CLI trusts this repo + approves MCP servers.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

AGENT=""
for cmd in agent cursor-agent; do
  if command -v "${cmd}" >/dev/null 2>&1; then
    AGENT="${cmd}"
    break
  fi
done

if [[ -z "${AGENT}" ]]; then
  echo "Install Cursor CLI first: curl https://cursor.com/install -fsS | bash" >&2
  exit 1
fi

echo "This opens an interactive Cursor agent session in ${ROOT}."
echo "When prompted:"
echo "  1. Trust this workspace"
echo "  2. Approve teams, universal-doc, and airtable MCP servers"
echo ""
echo "Then type: /mcp list"
echo "All three should show ready. Press Ctrl+D twice to exit."
echo ""

cd "${ROOT}"
exec "${AGENT}"
