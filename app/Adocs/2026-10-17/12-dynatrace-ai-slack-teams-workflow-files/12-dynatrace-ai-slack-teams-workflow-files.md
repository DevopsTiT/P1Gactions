# Dynatrace AI Slack Teams Workflow Files

## Decision tree

```
Need the files?
 WF-A (AI → Slack + Teams)     → 12-wfa-ai-notify-slack-teams.workflow.yaml
 WF-B (30m → one PD page)      → 12-wfb-30m-escalate-pagerduty.workflow.yaml
 Prompts                       → 12-ai-prompts.txt
 PD JSON sample                → 12-pagerduty-trigger.payload.json
 Chat message layout           → 12-slack-teams-message.txt
 Full solution narrative       → ../11-dynatrace-ai-slack-teams-solution/
 Existing SILVA+PD standard    → 2026-10-01/36-standard-flow-preview-then-post/
Import YAML → set connections → DRY_RUN true → test channel only → then activate
Never commit real PD routing keys or SILVA passwords
```

## Short takeaway

| File | What it is |
|---|---|
| `12-wfa-ai-notify-slack-teams.workflow.yaml` | Importable WF-A template (extract + message; Slack/Teams bind in UI) |
| `12-wfb-30m-escalate-pagerduty.workflow.yaml` | Importable WF-B template (preview → PD; DRY_RUN default true) |
| `12-ai-prompts.txt` | Copilot / generative AI prompt text |
| `12-pagerduty-trigger.payload.json` | Events API v2 body shape |
| `12-slack-teams-message.txt` | Chat body layout |
| Seq 11 folder | End-to-end solution write-up |
| Seq 36 (2026-10-01) | Your SILVA + PagerDuty preview-then-post standard (secrets — local only) |

## Summary

These are the relative workflow and helper files for the Slack+Teams Dynatrace AI solution. Templates ship with `isActive: false` and `DRY_RUN = true`. You bind Slack/Teams connectors and the PD key in the UI after import.

## Investigation

### How to import

1. Dynatrace → **Workflows** → Import / Create from file (tenant UI wording varies).  
2. Import `12-wfa-...yaml` then `12-wfb-...yaml`.  
3. Open each workflow: trigger stays **inactive** until you finish settings.  
4. WF-A: add Slack + Teams send tasks (or map Hub actions) using `chat_message` from `build-chat-message` / `emit-chat-payload`.  
5. Optional: insert **Prompt generative AI** between `extract-problem` and `build-chat-message`; write result into `ai_summary`.  
6. WF-B: set **Minimum duration = 30 minutes** on the Problem trigger; put routing key in script secret settings; keep `DRY_RUN = true` for first runs.  
7. Allowlist `events.pagerduty.com` if your environment requires it.  
8. Test with a low-impact problem and **test** Slack/Teams channels + **test** PD service.

### Task map WF-A

```
trigger (CREATED + ACTIVE)
  → extract-problem
  → (optional UI) Prompt generative AI
  → build-chat-message
  → emit-chat-payload   (replace with notify-slack + notify-teams)
```

### Task map WF-B

```
trigger (ACTIVE + Minimum duration 30m in UI)
  → extract-problem
  → preview-pagerduty
  → trigger-pagerduty   (skips if DRY_RUN or preview not ready)
  → (optional UI) Slack + Teams escalate note
```

## Result

| After import | You must still |
|---|---|
| WF-A | Bind Slack/Teams connections; optional Copilot task; activate when ready |
| WF-B | Set 30m min duration; set PD key; DRY_RUN false only after preview OK |
| Both | Use test channels/keys first |

## Data flow map

```
12-wfa-*.workflow.yaml
  problem → extract → build message → Slack+Teams (UI tasks)

12-wfb-*.workflow.yaml
  problem @30m → preview PD → trigger PD (dedup dynatrace-<id>)

Helpers: 12-ai-prompts.txt | 12-pagerduty-trigger.payload.json | 12-slack-teams-message.txt
```

## Related files

| Path | Purpose |
|---|---|
| `12-wfa-ai-notify-slack-teams.workflow.yaml` | WF-A template |
| `12-wfb-30m-escalate-pagerduty.workflow.yaml` | WF-B template |
| `12-ai-prompts.txt` | AI prompts |
| `12-pagerduty-trigger.payload.json` | PD payload sample |
| `12-slack-teams-message.txt` | Chat layout |
| `0-pic.md` / `1-investigation.md` / `2-result.md` / `3-glossary.md` | Support notes |
| `12.sh` | Git one-liners (do **not** git-add workflow YAMLs with secrets) |
| `../11-dynatrace-ai-slack-teams-solution/` | Solution design |
| `../../2026-10-01/36-standard-flow-preview-then-post/` | SILVA+PD standard (contains secrets — never commit) |

## Commands

See `12.sh`. None have been run. Do not commit workflow files that contain real keys.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/12-dynatrace-ai-slack-teams-workflow-files
git commit -m "dynatrace ai slack teams workflow file templates"
git push
```
