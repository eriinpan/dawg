#!/usr/bin/env bash
# Exit 0 during Mon–Fri 8:00 AM–4:00 PM America/Los_Angeles, else exit 1.

set -euo pipefail

if [[ "${SKIP_SCHEDULE_CHECK:-}" == "1" ]]; then
  exit 0
fi

python3 - <<'PY'
import os
import sys
from datetime import datetime
from zoneinfo import ZoneInfo

tz = ZoneInfo("America/Los_Angeles")
now = datetime.now(tz)

if now.weekday() >= 5:  # Saturday=5, Sunday=6
    sys.exit(1)

minutes = now.hour * 60 + now.minute
start = 8 * 60          # 8:00 AM
end = 16 * 60 + 1       # through 4:00 PM inclusive

if start <= minutes <= end:
    sys.exit(0)
sys.exit(1)
PY
