# Solution Summary Dynatrace AI Chat PD

## Decision tree

```
Problem you had
  PagerDuty AI in Slack = Not Connected (blocked on admin)
  Still want AI triage + optional page if ignored 30 min
  Want Slack and Teams both

Solution
  Dynatrace detects + writes AI text
  Dynatrace posts to Slack AND Teams (no PD Advance needed)
  If still open 30 min → ONE PagerDuty page only
  Keep PD for on-call schedule; Scribe/Shift optional later

Files to use
  Design:  seq 11
  Workflows: seq 12 (import WF-A + WF-B templates)
```

## Short takeaway

| Layer | Solution |
|---|---|
| AI triage / catch-up | Dynatrace generative AI in **WF-A** |
| Chat | **Slack** (primary) + **Teams** (mirror) via Dynatrace connectors |
| Escalate if ignored | **WF-B**: still Active after **30 minutes** → one PagerDuty trigger |
| PagerDuty Advance Slack/Teams | Optional later — **not required** for this solution |
| Do not replace | Scribe (meetings), Shift (schedules) |

## Summary

The solution is two Dynatrace workflows plus dual chat notify. Dynatrace owns the AI. Slack and Teams get the same summary. PagerDuty only pages after 30 minutes if the problem is still open. You are not blocked by PagerDuty `/ai` showing Not Connected.

## Investigation

### Why this design

| Constraint | Response |
|---|---|
| PD AI Slack Not Connected | Use Dynatrace → Slack/Teams instead of Paige in Slack |
| Need Teams too | Same AI message to both chats |
| Need page if no one handles it | WF-B minimum duration 30m → one PD incident |
| Avoid double page | Single PD service + `dedup_key = dynatrace-<problem_id>` |

### Solution picture

```
Davis problem opens
  → WF-A: AI summary → Slack #test-channel + Teams test channel

Still Active after 30 minutes
  → WF-B: preview → ONE PagerDuty trigger → Slack+Teams “escalated” note

PagerDuty Advance Connected = optional later
```

## Result

### Build order

| Step | What |
|---|---|
| 1 | Admin: Dynatrace Slack + Teams connectors; test channels |
| 2 | Import **WF-A** from seq 12; bind Slack/Teams; optional Copilot prompt |
| 3 | Import **WF-B** from seq 12; set 30m duration; test PD key; `DRY_RUN` first |
| 4 | Activate after tests pass |
| 5 | Optional: ask PD admin to connect Advance Slack/Teams for Paige/Scribe later |

### File map

| Need | Path under `Daily Files/2026-10-17/` |
|---|---|
| Full solution write-up | `11-dynatrace-ai-slack-teams-solution/` |
| **WF-A** yaml | `12-dynatrace-ai-slack-teams-workflow-files/12-wfa-ai-notify-slack-teams.workflow.yaml` |
| **WF-B** yaml | `12-dynatrace-ai-slack-teams-workflow-files/12-wfb-30m-escalate-pagerduty.workflow.yaml` |
| AI prompts | `12-.../12-ai-prompts.txt` |
| PD payload sample | `12-.../12-pagerduty-trigger.payload.json` |
| Chat message layout | `12-.../12-slack-teams-message.txt` |
| PD Slack blocked notes | `7-pagerduty-ai-slack-not-connected/` |
| Replace PD AI mapping | `9-dynatrace-ai-replace-pagerduty-ai/` |
| Teams+Slack OK | `10-add-teams-along-with-slack/` |
| SILVA+PD standard (secrets) | `../2026-10-01/36-standard-flow-preview-then-post/` — never commit secrets |

## Data flow map

```
Dynatrace problem
  → WF-A AI → Slack + Teams
  → WF-B @30m → one PD page
PD Advance chat AI → not on critical path
```

## Related files

| File | Purpose |
|---|---|
| `13-solution-summary-dt-ai-chat-pd.md` | This one-page solution |
| `0-pic.md` / `1-investigation.md` / `2-result.md` / `3-glossary.md` | Support |
| `13.sh` | Git one-liners (not run) |

## Commands

See `13.sh`. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/13-solution-summary-dt-ai-chat-pd
git commit -m "solution summary dynatrace ai slack teams pd"
git push
```
