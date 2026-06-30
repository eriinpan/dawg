# Local meeting minutes (Dogfooding)

Runs **on your Mac** every 30 minutes during work hours. Uses Cursor CLI + your existing MCPs (Teams, Google Doc, Airtable). No cloud automations, no webhooks, no My Machines.

## What it does

After a meeting ends (within ~45 min), each run:

1. Finds recently ended calendar meetings via **Teams MCP**
2. Fetches the transcript
3. Prepends minutes to the **Meeting Minutes** tab in your Google Doc
4. Adds **Airtable** rows when the title contains `dogfooding`
5. Sends a Teams **Notes to self** when minutes were written

Schedule: **Mon–Fri, 8:00 AM–4:00 PM Pacific**, every :00 and :30.

---

## Setup (5 minutes on your Mac)

### 1. Clone and open

```bash
git clone https://github.com/eriinpan/dawg.git
cd dawg
```

### 2. Install Cursor CLI (if needed)

```bash
curl https://cursor.com/install -fsS | bash
agent login
```

### 3. MCPs

You already have these in Cursor desktop. The local agent uses the same **`~/.cursor/mcp.json`**.

Required servers: **teams**, **universal-doc**, **airtable**

If starting fresh:

```bash
cp .cursor/mcp.json.example ~/.cursor/mcp.json
# Edit ~/.cursor/mcp.json — copy teams + universal-doc from Cursor Settings → MCP
# Add Airtable PAT with write access to base appfg7MQINxUwGcd7
```

Airtable token: [airtable.com/create/tokens](https://airtable.com/create/tokens/new)  
Scopes: `schema.bases:read`, `data.records:read`, `data.records:write`

### 4. Approve MCPs once (interactive)

```bash
./scripts/approve-mcps-once.sh
```

When the agent opens:

- Trust this workspace
- Approve **teams**, **universal-doc**, **airtable**
- Type `/mcp list` — all three should be **ready**
- Exit with Ctrl+D

### 5. Test

```bash
SKIP_SCHEDULE_CHECK=1 ./scripts/run-meeting-minutes.sh
```

Check `logs/run-*.log` and your Google Doc.

### 6. Install scheduler

```bash
./scripts/install-scheduler.sh
```

Your Mac must be **awake and logged in** during work hours (launchd runs locally).

Or run the guided setup:

```bash
./scripts/bootstrap.sh
```

---

## Commands

| Command | Purpose |
|---|---|
| `SKIP_SCHEDULE_CHECK=1 ./scripts/run-meeting-minutes.sh` | Test run anytime |
| `./scripts/run-meeting-minutes.sh` | Normal run (respects schedule) |
| `./scripts/install-scheduler.sh` | Install launchd job |
| `./scripts/uninstall-scheduler.sh` | Remove launchd job |
| `./scripts/approve-mcps-once.sh` | Re-approve MCPs if headless runs fail |

Logs: `logs/run-*.log`, `logs/launchd.out.log`, `logs/launchd.err.log`

---

## Turn off the old cloud stuff

1. **cursor.com/automations** → disable or delete **dawg**
2. Remove any **Power Automate** flow posting to the Cursor webhook
3. Optional: `./scripts/uninstall-scheduler.sh` on any old cron path if you had one elsewhere

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Cursor CLI not found` | `curl https://cursor.com/install -fsS \| bash` then `agent login` |
| MCP not approved / headless fails | Run `./scripts/approve-mcps-once.sh` again |
| `no-op (outside schedule)` | Normal outside Mon–Fri 8–4 PT; test with `SKIP_SCHEDULE_CHECK=1` |
| No transcript / nothing written | Transcript not ready yet; wait for next :30 run |
| Airtable 403 | PAT needs `data.records:write` on base `appfg7MQINxUwGcd7` |
| Mac asleep | Wake Mac or use `caffeinate`; launchd won't run while sleeping |

---

## Files

| Path | Purpose |
|---|---|
| `prompts/meeting-minutes.md` | Agent runbook (do not edit unless changing behavior) |
| `scripts/run-meeting-minutes.sh` | Main runner |
| `scripts/install-scheduler.sh` | macOS launchd installer |
| `scripts/uninstall-scheduler.sh` | Remove scheduler |
| `scripts/bootstrap.sh` | Guided setup |
| `.cursor/mcp.json.example` | MCP template |
| `docs/archive/` | Old cloud/webhook docs (deprecated) |

---

## One-off catch-up scripts

If Airtable rows were missed for past meetings, run these prompts manually in Cursor (with MCPs):

- `prompts/airtable-catchup.md` — sync all missing dogfooding action items from the doc
- `prompts/airtable-latest-meeting.md` — sync only the latest dogfooding meeting
