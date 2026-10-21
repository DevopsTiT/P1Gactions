# WFA WFB New Workflows

```
Need latest importable workflows?
 → Import 23-wfa-…yaml and 23-wfb-…yaml
 → Paste SLACK_WEBHOOK_URL only in Dynatrace UI (not in git)
 → Allowlist hooks.slack.com
 → WF-A: DRY_RUN false → Run → #test-channel
 → WF-B: 30m + PD_ROUTING_KEY → test DRY_RUN then go live
```

| File | Job |
|---|---|
| `23-wfa-ai-notify-slack-webhook.workflow.yaml` | New problem → Slack Incoming Webhook |
| `23-wfb-30m-escalate-pagerduty.workflow.yaml` | Still Active 30m → PagerDuty (+ optional Slack) |

## Summary

These are the current replacement workflows with the fixes you already hit: `await result("task")`, global `fetch()`, and empty URL placeholders. Import them, paste the webhook only in Dynatrace, then run.

## Fixes included

| Issue you saw | Fix in this pack |
|---|---|
| `ex.result is not a function` | `await result("…")` |
| `DRY_RUN_true` skipped post | `DRY_RUN = false` in WF-A scripts |
| `httpClient.fetch is not a function` | `await fetch(…)` |
| Secrets in git | `SLACK_WEBHOOK_URL = ""` — paste in UI only |

## After import — WF-A

1. **Settings → External requests** → allow `hooks.slack.com`  
2. Tasks `preview-slack-webhook` and `post-slack-webhook`:

```
const DRY_RUN = false;
const SLACK_WEBHOOK_URL = "https://hooks.slack.com/services/…";  // UI only
```

3. Run on-demand → new message in `#test-channel`  
4. Turn trigger on when ready  

## After import — WF-B

1. Trigger → Minimum duration **30 minutes**  
2. Set `PD_ROUTING_KEY` in preview + trigger scripts  
3. Optional: same Slack URL on `notify-slack-webhook`  
4. `DRY_RUN true` first, then `false`  

## Task chains

```
WF-A:
  extract-problem → build-chat-message → preview-slack-webhook → post-slack-webhook

WF-B:
  extract-problem → preview-pagerduty → trigger-pagerduty → notify-slack-webhook (optional)
```

## Data flow map

```
Davis problem CREATED
  → WF-A builds chat_message
  → fetch(hooks.slack.com) {"text": …}
  → #test-channel

Still Active ≥ 30m
  → WF-B → PagerDuty Events API
  → optional Slack note
```

## Related files

| Path | Role |
|---|---|
| Both folders `…/23-wfa-wfb-new-workflows/` | Import YAMLs |
| `../22-slack-webhook-paste-in-dynatrace-only/` | Where to paste URL |
| `23.sh` | Mirror |

## Commands

See [23.sh](./23.sh).
