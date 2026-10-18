# Dynatrace AI Replace PD All Files

## Decision tree

```
Need the full solution file set?
 → Importables first: WF-A + WF-B YAML + prompts + PD payload
 → Event-path guide: 1-event-dynatrace-ai-replace-pd-ai.md
 → Design / replace matrix: 9, 11, 13
 → Assistant steps: 16
 Missing secrets?
 → Bind Connections in Dynatrace UI after import (never commit tokens)
```

## Short takeaway

| Kind | Files in this folder |
|---|---|
| Import into Dynatrace | `12-wfa-*.workflow.yaml`, `12-wfb-*.workflow.yaml` |
| Prompts / message / PD sample | `12-ai-prompts.txt`, `12-slack-teams-message.txt`, `12-pagerduty-trigger.payload.json` |
| How the event path works | `1-event-dynatrace-ai-replace-pd-ai.md` |
| Replace vs keep + design | `9-…`, `11-…`, `13-…` |
| Assistant setup steps | `16-dynatrace-ai-assistant-steps.md` |

## Summary

One folder with every file for the Dynatrace AI Assistant path that replaces PagerDuty AI triage when a Davis problem opens. Import WF-A and WF-B, bind Slack/Teams/PagerDuty connections in the UI, test, then activate.

## Investigation

### Bundle contents (this folder)

| File | What it is |
|---|---|
| `12-wfa-ai-notify-slack-teams.workflow.yaml` | **WF-A**: problem open → AI summary → Slack/Teams |
| `12-wfb-30m-escalate-pagerduty.workflow.yaml` | **WF-B**: still Active 30m → one PD page |
| `12-ai-prompts.txt` | Generative AI prompt text |
| `12-pagerduty-trigger.payload.json` | Sample PD Events API trigger body |
| `12-slack-teams-message.txt` | Chat message layout hint |
| `12-dynatrace-ai-slack-teams-workflow-files.md` | How to import/bind workflows |
| `1-event-dynatrace-ai-replace-pd-ai.md` | Event timeline solution (today seq 1) |
| `9-dynatrace-ai-replace-pagerduty-ai.md` | Replace vs keep matrix |
| `11-dynatrace-ai-slack-teams-solution.md` | Dual chat + 30m design |
| `13-solution-summary-dt-ai-chat-pd.md` | One-page solution summary |
| `16-dynatrace-ai-assistant-steps.md` | Step-by-step Assistant setup |

### Original source folders (also mirrored under Files / Adocs)

| Folder | Purpose |
|---|---|
| `Daily Files/2026-10-18/1-event-dynatrace-ai-replace-pd-ai/` | Event-path solution + support md |
| `Daily Files/2026-10-17/9-dynatrace-ai-replace-pagerduty-ai/` | Replace matrix |
| `Daily Files/2026-10-17/11-dynatrace-ai-slack-teams-solution/` | Full solution design |
| `Daily Files/2026-10-17/12-dynatrace-ai-slack-teams-workflow-files/` | Original workflow package |
| `Daily Files/2026-10-17/13-solution-summary-dt-ai-chat-pd/` | Short summary |
| `Daily Files/2026-10-17/16-dynatrace-ai-assistant-steps/` | Assistant steps |

### Absolute paths (CursorFiles)

```
/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-18/2-dt-ai-replace-pd-all-files/
/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-18/1-event-dynatrace-ai-replace-pd-ai/
/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-17/9-dynatrace-ai-replace-pagerduty-ai/
/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-17/11-dynatrace-ai-slack-teams-solution/
/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-17/12-dynatrace-ai-slack-teams-workflow-files/
/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-17/13-solution-summary-dt-ai-chat-pd/
/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-17/16-dynatrace-ai-assistant-steps/
```

### Mirrors

```
/Users/k/Work/AIProjects/Files/2026-10-18/2-dt-ai-replace-pd-all-files/
/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-18/2-dt-ai-replace-pd-all-files/
```

## Result

| Use | Do this |
|---|---|
| Import | Open Dynatrace Workflows → import `12-wfa-…` then `12-wfb-…` |
| Bind | Slack, Teams, PagerDuty connections; test channels; test routing key |
| Test | Keep `isActive` false / `DRY_RUN` until safe |
| Read first | `1-event-dynatrace-ai-replace-pd-ai.md` then `13-solution-summary-…` |

## Data flow map

```
This bundle folder
  → WF-A yaml  → Dynatrace import → AI → Slack/Teams
  → WF-B yaml  → Dynatrace import → 30m → one PD page
  → prompts / payload / message  → fill workflow tasks
  → md guides  → human runbook
```

## Related files

| File | Purpose |
|---|---|
| `2-dt-ai-replace-pd-all-files.md` | This index |
| All `12-*` and `*.md` copies above | Bundle payload |
| `2.sh` | Git one-liners (not run) |

## Commands

See `2.sh`. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-18/2-dt-ai-replace-pd-all-files
git commit -m "dynatrace ai replace pd all files bundle"
git push
```
