# Cloud automation setup (Cursor + optional Power Automate)

Use this with your **dawg** automation on [cursor.com/automations](https://cursor.com/automations). Goal: **one cloud run per meeting end**, not local cron.

---

## Step 0 — Make the cloud automation actually work (do this first)

Your Teams / Google / Airtable MCPs are **Command (stdio)** servers with paths on your Mac. They **cannot** run on Cursor’s default cloud VM. You need **My Machines**.

### A. Runtime = My Machines

1. Open **dawg** → **Settings** (or environment / runtime section).
2. Choose **My Machines** (not “Cursor Cloud” only).
3. Your Mac must stay on and connected during work hours (or use a always-on dev machine).

### B. My Machines worker

Worker should be running (Cursor usually starts it). Verify:

```bash
pgrep -fl worker-server
```

If nothing shows, start from Terminal:

```bash
cursor-agent worker start --verbose
```

### C. MCPs inside the automation (not just global Settings)

Automations **only** load MCPs listed under **Tools** in that automation.

1. **Tools** → you should see **teams**, **universal-doc**, **airtable** (all green).
2. If missing: **+ Add Tool or MCP** → add each as **Command** MCP (same config as `~/.cursor/mcp.json`).
3. Re-authenticate if any show “needs setup”: Teams login, Google token, Airtable PAT.

### D. Remove broken / duplicate pieces

| Remove | Why |
|--------|-----|
| **Cron / schedule trigger** | Conflicts with webhook; wrong timezone; rate limits |
| **Send to Microsoft Teams** tool (channel picker) | Channels only — use Teams MCP + `48:notes` in instructions instead |
| **Local macOS cron** | `scripts/uninstall-scheduler.sh` |

### E. Instructions + trigger

| Field | Value |
|--------|--------|
| **Trigger** | **Webhook** only |
| **Instructions** | Paste full contents of `prompts/meeting-minutes-webhook.md` |
| **Repository** | **None** (no git repo needed) |

Save → copy **Webhook URL** and **Generate auth header** (`Bearer crsr_...`).

### F. Quick test (no Power Automate yet)

In Terminal (paste your real URL and token):

```bash
curl -sS -X POST 'YOUR_WEBHOOK_URL' \
  -H 'Authorization: Bearer crsr_YOUR_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "eventId": "manual-test-1",
    "meetingTitle": "Hotstar Dogfooding Workstream Working Session",
    "startTime": "2026-06-30T17:00:00Z",
    "endTime": "2026-06-30T17:30:00Z",
    "organizerEmail": "erin.pan@disney.com"
  }'
```

Then check **dawg → Runs**. A healthy run calls Teams / universal-doc / Airtable MCP tools (not instant `no-op` from wrong prompt).

---

## Why you see “running consecutively too many times”

Cursor rate-limits **concurrent / back-to-back automation runs**. Common causes:

1. **Cron + webhook both enabled** on the same automation (double triggers)
2. **Local macOS cron** still calling `run-meeting-minutes.sh`
3. **Recurrence flow** that POSTs every N minutes (poll loop)
4. **Power Automate retries** the HTTP step after timeout (each retry = new Cursor run)
5. **Parallel flow runs** (multiple meetings ending close together)
6. **“Event updated” trigger** firing many times for one meeting

Fix: **webhook only**, **dedup by event ID**, **concurrency = 1**, **no HTTP retries**, **12–15 min delay** before POST.

---

## Step 1 — Fix dawg in Cursor

1. Open **dawg** in [cursor.com/automations](https://cursor.com/automations).
2. **Remove all cron / scheduled triggers.** Webhook only.
3. Add trigger: **Webhook**.
4. **Save** the automation → copy **Webhook URL** and click **Generate auth header** → copy `Authorization: Bearer crsr_...`.
5. Paste instructions from `prompts/meeting-minutes-webhook.md` (not the cron version with :00/:30 guard).
6. Tools: Teams, universal-doc, Airtable MCPs (My Machines or cloud, whichever you use).
7. Repository: **None** (no code repo needed).

Disable local cron on your Mac:

```bash
"/Users/erin.pan/tpm weekly automation/scripts/uninstall-scheduler.sh"
```

---

## Step 2 — Create the Power Automate flow

**Name:** `Dogfooding minutes → Cursor (deduped)`

### Flow settings (important)

- **Concurrency control:** **Off** for parallel runs → limit to **1** concurrent run (wording varies: “Limit number of concurrent runs” = 1).
- This queues meetings instead of hitting Cursor with 5 webhooks at once.

### Trigger (pick ONE — do not use Recurrence)

**Recommended:** Office 365 Outlook → **When an event ends (V4)**  
(or the closest “when an event ends” trigger in your tenant)

- Calendar: your default calendar
- Only events you organize or accept (as available)

**Do NOT use:**

- Recurrence every 5 minutes + “Get events” + HTTP (this causes the flood)
- “When an event is created or modified” without heavy filtering

### Condition — work hours (Pacific)

After trigger, add **Condition**:

- Convert `End time` to `Pacific Standard Time`
- `dayOfWeek` is not Saturday/Sunday
- `hour(End)` between 8 and 16 inclusive (adjust if your connector exposes local time differently)

If false → **Terminate** (Succeeded).

### Dedup — one webhook per calendar event

Use a **SharePoint list** (or Dataverse table) `MeetingMinutesWebhookLog`:

| Column | Type |
|---|---|
| Title | Event ID (Outlook `Id` from trigger) |
| ProcessedAt | DateTime |

Steps:

1. **Get items** — filter `Title eq '@{triggerOutputs()?['body/id']}'`
2. **Condition** — if count > 0 → **Terminate** (already sent)
3. **Create item** — store event ID (before HTTP, so retries don’t double-post if create is idempotent use only after successful HTTP — see below)

**Safer order:**

1. Get items → if exists, Terminate
2. Delay 12 minutes (transcript buffer)
3. HTTP POST to Cursor
4. On success only → Create item in SharePoint list

### Delay

**Delay for 12 minutes** (or 15) after the condition passes — Teams transcripts are often not ready at second 0.

### HTTP — call Cursor webhook

Action: **HTTP**

| Field | Value |
|---|---|
| Method | POST |
| URI | *(dawg webhook URL from Cursor)* |
| Headers | `Authorization` = `Bearer crsr_...` *(full value from Generate auth header)* |
| Headers | `Content-Type` = `application/json` |
| Body | see JSON below |

**Configure advanced options:**

- **Retry policy:** **None** or interval count **0** (critical — stops retry storms)
- Timeout: 30–60 seconds (Cursor may return before agent finishes; that’s OK)

**Body example:**

```json
{
  "eventId": "@{triggerOutputs()?['body/id']}",
  "meetingTitle": "@{triggerOutputs()?['body/subject']}",
  "startTime": "@{triggerOutputs()?['body/start']}",
  "endTime": "@{triggerOutputs()?['body/end']}",
  "organizerEmail": "@{triggerOutputs()?['body/organizer/emailAddress/address']}"
}
```

Use dynamic content picker for fields if `@triggerOutputs()` syntax differs in your trigger version.

### Optional — second attempt if no transcript

Only if needed:

- Duplicate branch with **Delay 20 minutes** total (second flow or delayed action)
- Same dedup list check — allow max **2** rows per event ID with a `Attempt` column
- Most teams skip this and rely on manual backfill

---

## Step 3 — Verify

1. Run flow **Test** with a short calendar block (or wait for a real meeting end).
2. In **dawg → Runs**, you should see **one run** ~12 min after end.
3. If you see many runs at once, cron is still on or dedup is missing.

---

## Troubleshooting

| Symptom | Fix |
|---|---|
| Many runs at 1 AM–9 AM PT | Cron still UTC on dawg — remove cron trigger |
| Same meeting triggers 5+ times | Add SharePoint dedup; change trigger away from “modified” |
| 401 from Cursor | Regenerate webhook auth header; paste full `Bearer crsr_...` |
| Agent no-ops instantly | Use `meeting-minutes-webhook.md`; old prompt blocks non-:00/:30 times |
| no-op (no transcript yet) | Normal once; increase delay to 15–20 min |
| Concurrent limit error | Flow concurrency = 1; remove cron; cancel stuck runs in dawg Runs tab |

---

## Stuck / failed runs in Cursor

Automations → **dawg** → **Runs** → cancel any **In progress** runs. Ask a team admin if you cannot cancel a colleague’s stuck run.
