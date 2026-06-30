#!/usr/bin/env bash
# Remove the launchd meeting-minutes job.

set -euo pipefail

LABEL="com.eriinpan.dawg-meeting-minutes"
PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"

launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true

if [[ -f "${PLIST}" ]]; then
  rm -f "${PLIST}"
  echo "Removed ${PLIST}"
else
  echo "No plist at ${PLIST} (already removed)"
fi

echo "Scheduler uninstalled."
