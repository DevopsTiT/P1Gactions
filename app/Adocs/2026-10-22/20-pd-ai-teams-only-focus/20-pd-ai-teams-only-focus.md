# PD AI Teams Only Focus

```
PD AI / chat help from now on?
 → Use Microsoft Teams only
 → Skip Slack-first wording unless user asks for Slack
 → Rule file: ~/.cursor/rules/pagerduty-ai-teams-only.mdc
```

| Key point | Detail |
|---|---|
| Decision | PagerDuty AI answers and examples use **Teams only** |
| Do not default to | Slack, `/pd` Slack commands, Slack Side Panel |
| Runtime path | Alert → PD incident → Teams notify → ask AI in Teams → act in PD |
| Rule | `pagerduty-ai-teams-only.mdc` (always apply) |

## Summary

Standing preference: when talking about PagerDuty AI (how it reacts to alerts, capabilities, examples, setup), stay on **Microsoft Teams**. Do not lead with Slack.

## Teams-only runtime (pic)

```
Alert / Dynatrace problem
  → PagerDuty incident + page
  → Teams channel (PagerDuty app)
  → Ask PagerDuty AI in Teams (Catch me up / status / Scribe)
  → Fact-check → act in PagerDuty
```

## Data flow map

```
PD AI context  →  Teams only (default)
Slack          →  only if user explicitly asks
```

## Related files

| File | Role |
|---|---|
| `~/.cursor/rules/pagerduty-ai-teams-only.mdc` | Persistent rule |
| `18-pd-ai-alert-reaction-capabilities-reply/` | Earlier reply (may still mention Slack) |
| `19-pd-ai-detailed-alert-example/` | Example already Teams-channel framed |
| `20.sh` | Dual-write |

## Commands

See [20.sh](20.sh).
