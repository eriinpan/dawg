# dawg — local meeting-minutes automation

Bash + inline-Python scripts that drive the **Cursor CLI agent** (`agent` / `cursor-agent`) to
summarize recently-ended meetings and write minutes to a Google Doc / Airtable via MCP servers
(Teams, universal-doc, Airtable). There is no package manager, build step, or test suite — the
"application" is `scripts/run-meeting-minutes.sh`, which shells out to the Cursor CLI with the
runbook in `prompts/meeting-minutes.md`. See `README.md` for the full command reference.

## Cursor Cloud specific instructions

- **Runtime dependency = the Cursor CLI.** The startup update script installs it
  (`curl https://cursor.com/install -fsS | bash`, idempotent). It creates `agent` and
  `cursor-agent` symlinks in `~/.local/bin`, which must be on `PATH`
  (`export PATH="$HOME/.local/bin:$PATH"`, already appended to `~/.bashrc` during setup).
  System deps `bash`, `python3` (3.9+ for `zoneinfo`), `node`/`npx`, and `curl` are preinstalled.
- **Lint / test / build:** none are configured. Use `bash -n scripts/*.sh scripts/lib/*.sh` as a
  syntax check ("lint"). There are no automated tests and nothing to build.
- **Schedule guard:** `scripts/is-work-hours.sh` exits 0 only Mon–Fri 08:00–16:00
  **America/Los_Angeles**; otherwise the runner is a no-op. Bypass with
  `SKIP_SCHEDULE_CHECK=1` for any run outside that window (this is expected in the cloud VM,
  whose clock is UTC).
- **Running the app requires auth:** `cursor-agent` needs `CURSOR_API_KEY` (or interactive
  `agent login`) or it exits with "Authentication required". The runner reaches the agent-launch
  step and stops here without a key.
- **MCP config gate:** the runner requires `~/.cursor/mcp.json` (or `./.cursor/mcp.json`) to exist.
  Copy `.cursor/mcp.json.example` to `~/.cursor/mcp.json`. Real end-to-end runs additionally need
  authenticated **teams**, **universal-doc**, and **airtable** MCP servers tied to a real user's
  accounts — the runbook writes to a live Google Doc and Airtable base, so do **not** execute the
  real runbook against production data as a setup smoke test; use a trivial `cursor-agent -p`
  prompt to verify the engine instead.
- **macOS-only pieces:** `install-scheduler.sh` / `uninstall-scheduler.sh` use `launchctl`
  (launchd) and do not work on the Linux VM. The rest of the scripts are cross-platform.
