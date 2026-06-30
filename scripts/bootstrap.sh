#!/usr/bin/env bash
# One-command local setup (run on your Mac after cloning).

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "=== Dawg local meeting minutes setup ==="
echo ""

if ! command -v agent >/dev/null 2>&1 && ! command -v cursor-agent >/dev/null 2>&1; then
  echo "Installing Cursor CLI..."
  curl https://cursor.com/install -fsS | bash
  echo ""
  echo "Add Cursor CLI to your PATH, then run: agent login"
  echo "Re-run this script after login."
  exit 0
fi

chmod +x "${ROOT}/scripts/"*.sh
mkdir -p "${ROOT}/logs" "${ROOT}/.cursor"

if [[ ! -f "${HOME}/.cursor/mcp.json" ]]; then
  echo "No ~/.cursor/mcp.json found."
  echo "Copy the example and add your tokens:"
  echo "  cp ${ROOT}/.cursor/mcp.json.example ~/.cursor/mcp.json"
  echo "  open ~/.cursor/mcp.json"
  echo ""
  read -r -p "Press Enter after you've configured MCPs (or Ctrl+C to stop)..."
else
  echo "Found ~/.cursor/mcp.json"
fi

echo ""
echo "Step 1/3: Approve MCPs (interactive — trust workspace + approve servers)"
echo "  Run: ${ROOT}/scripts/approve-mcps-once.sh"
echo ""
read -r -p "Press Enter when MCPs show ready in /mcp list..."

echo ""
echo "Step 2/3: Test run (bypasses schedule guard)"
SKIP_SCHEDULE_CHECK=1 "${ROOT}/scripts/run-meeting-minutes.sh"

echo ""
echo "Step 3/3: Install scheduler"
read -r -p "Install launchd scheduler? [y/N] " ans
if [[ "${ans}" =~ ^[Yy]$ ]]; then
  "${ROOT}/scripts/install-scheduler.sh"
fi

echo ""
echo "Done. Meeting minutes will run locally on your Mac during work hours."
echo "Disable cloud automation (dawg) in cursor.com/automations if still enabled."
