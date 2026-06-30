# Dogfooding Meeting Minutes

Automates meeting minutes from Teams transcripts into a Google Doc (+ Airtable for dogfooding meetings).

## Recommended: Cursor cloud automation (**dawg**)

Runs on **Cursor Automations** with a **webhook** trigger (and optional Power Automate when a calendar event ends).

**Setup guide:** [`prompts/power-automate-webhook-setup.md`](prompts/power-automate-webhook-setup.md)

**Agent instructions:** copy [`prompts/meeting-minutes-webhook.md`](prompts/meeting-minutes-webhook.md) into the automation.

### Requirements (cloud)

- **My Machines** runtime (stdio MCPs run on your Mac, not Cursor’s VM)
- **teams**, **universal-doc**, **airtable** MCPs added under **Tools** in the automation
- **Webhook** trigger only (no cron on the same automation)
- Mac awake + worker connected during work hours

### What each run does

1. Receives meeting info from webhook (or scans recent calendar if body empty)
2. Fetches transcript via Teams MCP
3. Prepends minutes to the **Meeting Minutes** tab in your Google Doc
4. Adds Airtable rows when title contains `dogfooding`
5. Sends a Teams **Notes to self** (`48:notes`) when minutes were written

---

## Legacy: local macOS cron (optional)

Only if you explicitly want runs on your Mac without the cloud automation:

```bash
SKIP_SCHEDULE_CHECK=1 scripts/run-meeting-minutes.sh   # test
scripts/install-scheduler.sh                            # install cron
scripts/uninstall-scheduler.sh                          # remove cron
```

Uses [`prompts/meeting-minutes.md`](prompts/meeting-minutes.md) and `~/.cursor/mcp.json`.

---

## Files

| Path | Purpose |
|---|---|
| `prompts/meeting-minutes-webhook.md` | **Cloud** automation instructions |
| `prompts/power-automate-webhook-setup.md` | Cloud + Power Automate setup |
| `prompts/meeting-minutes.md` | Local cron instructions |
| `scripts/run-meeting-minutes.sh` | Local test / cron wrapper |
| `logs/` | Local run logs |
