#!/usr/bin/env bash
# Install macOS launchd job: run meeting minutes every 30 min, Mon–Fri, 8 AM–4 PM PT.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LABEL="com.eriinpan.dawg-meeting-minutes"
PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"
RUN_SCRIPT="${ROOT}/scripts/run-meeting-minutes.sh"

chmod +x "${ROOT}/scripts/"*.sh

mkdir -p "${HOME}/Library/LaunchAgents"
mkdir -p "${ROOT}/logs"

python3 - "${PLIST}" "${RUN_SCRIPT}" "${ROOT}" "${LABEL}" <<'PY'
import plistlib
import sys
from pathlib import Path

plist_path, run_script, root, label = sys.argv[1:5]

intervals = []
for weekday in range(2, 7):  # Mon–Fri (launchd: 1=Sun, 2=Mon … 6=Fri)
    for hour in range(8, 16):
        for minute in (0, 30):
            intervals.append({"Weekday": weekday, "Hour": hour, "Minute": minute})
    intervals.append({"Weekday": weekday, "Hour": 16, "Minute": 0})

data = {
    "Label": label,
    "ProgramArguments": ["/bin/bash", run_script],
    "WorkingDirectory": root,
    "StartCalendarInterval": intervals,
    "StandardOutPath": str(Path(root) / "logs" / "launchd.out.log"),
    "StandardErrorPath": str(Path(root) / "logs" / "launchd.err.log"),
    "EnvironmentVariables": {
        "PATH": "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin",
    },
}

Path(plist_path).write_bytes(plistlib.dumps(data))
print(f"Wrote {plist_path} ({len(intervals)} schedule slots/week)")
PY

launchctl bootout "gui/$(id -u)/${LABEL}" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "${PLIST}"
launchctl enable "gui/$(id -u)/${LABEL}" 2>/dev/null || true

echo ""
echo "Installed. Scheduler runs ${RUN_SCRIPT}"
echo "  Mon–Fri, every :00 and :30 from 8:00 AM–4:00 PM Pacific"
echo ""
echo "Test now (ignores schedule):"
echo "  SKIP_SCHEDULE_CHECK=1 ${RUN_SCRIPT}"
echo ""
echo "Logs: ${ROOT}/logs/"
