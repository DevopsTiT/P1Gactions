# WF-A WF-B Webhook Fill In

```
Just imported the webhook replacement YAMLs?
 → WF-A: fill SLACK_WEBHOOK_URL (preview + post) + DRY_RUN
 → WF-B: fill Minimum duration 30m + PD_ROUTING_KEY + DRY_RUN
 → Optional: TEAMS_WEBHOOK_URL (WF-A) / Slack note URL (WF-B)
 → Test with DRY_RUN true → false → then turn trigger on
 Do not fill: problem id, title, URL (Dynatrace fills those)
```

| Workflow | Must fill | Optional | Auto (do not type) |
|---|---|---|---|
| **WF-A** | `SLACK_WEBHOOK_URL` in 2 scripts; `DRY_RUN` | `TEAMS_WEBHOOK_URL`; AI prompt task | problem_id, title, description, severity, problem_url, chat_message |
| **WF-B** | Minimum duration **30m**; `PD_ROUTING_KEY` in 2 scripts; `DRY_RUN` | `SLACK_WEBHOOK_URL` on notify task | problem fields; dedup_key |

## Summary

For the **webhook replacement** workflows you only paste secrets and switches inside Dynatrace. Dynatrace already builds the problem text. Slack channel is already chosen when you created the Incoming Webhook (`#test-channel`).

---

## WF-A — what to fill

**File:** `11-wfa-ai-notify-slack-webhook.workflow.yaml`

### Required

| # | Fill in | Where (task) | What to put | How to get it |
|---|---|---|---|---|
| 1 | `SLACK_WEBHOOK_URL` | `preview-slack-webhook` script | Your Incoming Webhook URL | Slack app → Incoming Webhooks → URL for `#test-channel` (prefer a **new** URL if the old one was in a screenshot) |
| 2 | `SLACK_WEBHOOK_URL` | `post-slack-webhook` script | **Same** URL as #1 | Copy from #1 — both must match |
| 3 | `DRY_RUN` | Both scripts above | First `true`, later `false` | Keep both scripts the same value |

Example shape (paste real URL only in Dynatrace, not in git):

```
const DRY_RUN = true;
const SLACK_WEBHOOK_URL = "https://hooks.slack.com/services/…";  // Dynatrace UI only
const TEAMS_WEBHOOK_URL = "";
```

### Optional

| # | Fill in | Where | What to put |
|---|---|---|---|
| 4 | `TEAMS_WEBHOOK_URL` | Both preview + post scripts | Teams Incoming Webhook / connector URL, or leave `""` |
| 5 | Prompt generative AI | New task between `extract-problem` and `build-chat-message` | Your AI prompt; map output into `ai_summary` |
| 6 | Categories / entity tags | Trigger | Narrow before production |
| 7 | Trigger active | Trigger UI | Keep **off** until Slack test works → then **on** |

### You do **not** fill

| Field | Why |
|---|---|
| Slack channel name in the workflow | Webhook is already bound to `#test-channel` |
| Bot token / Hub Connection | Webhook replaces that |
| problem_id, title, description, severity, problem_url | From the Davis problem event |
| `chat_message` | Built by `build-chat-message` |

### Done when

| Check | Pass |
|---|---|
| Preview result | `ready: true`, no `missing_SLACK_WEBHOOK_URL` |
| After `DRY_RUN = false` Run | Message appears in `#test-channel` |
| Trigger | Turned on only after that |

---

## WF-B — what to fill

**File:** `11-wfb-30m-escalate-pagerduty.workflow.yaml`

### Required

| # | Fill in | Where | What to put | How to get it |
|---|---|---|---|---|
| 1 | Minimum duration | Problem trigger UI | **30 minutes** | Trigger settings after import |
| 2 | `PD_ROUTING_KEY` | `preview-pagerduty` script | Test service Events API v2 key | PagerDuty → Service → Integrations → Events API V2 |
| 3 | `PD_ROUTING_KEY` | `trigger-pagerduty` script | **Same** key as #2 | Copy from #2 |
| 4 | `DRY_RUN` | Both PD scripts | First `true`, later `false` | Keep both the same |

Example shape:

```
const DRY_RUN = true;
const PD_ROUTING_KEY = "…";  // Dynatrace UI only — never commit
```

### Optional

| # | Fill in | Where | What to put |
|---|---|---|---|
| 5 | `SLACK_WEBHOOK_URL` | `notify-slack-webhook` | Same webhook as WF-A for a short “paged” note, or leave `""` to skip |
| 6 | `DRY_RUN` on Slack note | Same task | Match PD scripts until you want a real Slack note |
| 7 | Trigger active | Trigger UI | Off until PD preview looks right |

### You do **not** fill

| Field | Why |
|---|---|
| `dedup_key` | Built as `dynatrace-<problem_id>` |
| problem fields | From the event |
| PagerDuty URL | Already `https://events.pagerduty.com/v2/enqueue` in the script |

### Done when

| Check | Pass |
|---|---|
| Preview | `ready: true`, key present (shown redacted) |
| `DRY_RUN false` test | One test incident on your **test** PD service |
| Slack note (if used) | Short message in `#test-channel` |

---

## Fill-in order (safe)

```
1. Import both YAMLs
2. WF-A: paste SLACK_WEBHOOK_URL in preview + post (Dynatrace only)
3. WF-A: DRY_RUN true → Run → check preview
4. WF-A: DRY_RUN false → Run → see #test-channel
5. WF-B: set 30m + PD_ROUTING_KEY (both scripts) + DRY_RUN true
6. WF-B: preview OK → DRY_RUN false on test service
7. Optional: WF-B Slack URL for escalate note
8. Turn triggers on
```

## Quick checklist

```
WF-A
[ ] SLACK_WEBHOOK_URL in preview-slack-webhook
[ ] SLACK_WEBHOOK_URL in post-slack-webhook (same)
[ ] DRY_RUN true then false (both scripts match)
[ ] (optional) TEAMS_WEBHOOK_URL
[ ] Trigger on only after Slack message OK

WF-B
[ ] Minimum duration = 30 minutes
[ ] PD_ROUTING_KEY in preview-pagerduty
[ ] PD_ROUTING_KEY in trigger-pagerduty (same)
[ ] DRY_RUN true then false (both match)
[ ] (optional) SLACK_WEBHOOK_URL on notify-slack-webhook
[ ] Trigger on only after PD test OK
```

## Data flow map

```
You fill (secrets / switches)
  SLACK_WEBHOOK_URL  →  WF-A preview + post
  DRY_RUN            →  WF-A + WF-B scripts
  PD_ROUTING_KEY     →  WF-B preview + trigger
  30m duration       →  WF-B trigger UI

Dynatrace fills (event)
  problem_id / title / description / url
    → chat_message (WF-A)
    → PD payload + dedup_key (WF-B)
```

## Related files

| File | Role |
|---|---|
| `../11-wfa-wfb-webhook-replacement/` | The YAML workflows |
| `../7-slack-incoming-webhook-wfa/` | How the Slack URL was created |
| `../2-how-to-get-wfa-wfb-info/` | How to get PD routing key |
| `12.sh` | Copy one-liners |

## Commands

See [12.sh](./12.sh).
