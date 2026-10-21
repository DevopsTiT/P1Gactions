# WF-A WF-B Webhook Replacement

```
curl webhook test returned ok in #test-channel?
 → Import 11-wfa-ai-notify-slack-webhook.workflow.yaml
 → Paste SLACK_WEBHOOK_URL only in Dynatrace UI (both preview + post tasks)
 → DRY_RUN true → Run → message looks good → DRY_RUN false → activate trigger
 → Import 11-wfb-… → set 30m + PD_ROUTING_KEY → optional same Slack URL for note
 URL was in a screenshot/editor?
 → Revoke that webhook → create a new URL → paste only the new one in Dynatrace
```

| Key point | Detail |
|---|---|
| What changed | WF-A no longer needs Hub Slack Connection / `xoxb` bot token |
| How Slack is sent | HTTP POST `{"text": chat_message}` to Incoming Webhook |
| Your curl proof | Same POST shape the workflow uses |
| Secrets in git | Never — leave `SLACK_WEBHOOK_URL = ""` in YAML; paste in Dynatrace only |

## Summary

These two YAML files replace the old “bind Slack connector in the UI” WF-A path. Because your Incoming Webhook already posted **WF-A webhook test** to `#test-channel`, wire that same URL into the Dynatrace scripts after import (not into git).

## What to import

| File | Replaces | Job |
|---|---|---|
| `11-wfa-ai-notify-slack-webhook.workflow.yaml` | Old `12-wfa-ai-notify-slack-teams.workflow.yaml` Slack connector path | New problem → build message → preview → POST Slack webhook |
| `11-wfb-30m-escalate-pagerduty.workflow.yaml` | Old `12-wfb-30m-escalate-pagerduty.workflow.yaml` (+ optional Slack note) | Still Active 30m → preview/POST PagerDuty → optional Slack note |

## WF-A task chain

```
extract-problem
  → build-chat-message
  → preview-slack-webhook   (checks URL + DRY_RUN; shows JSON)
  → post-slack-webhook      (real POST when DRY_RUN false)
```

| Setting | Where | What you put |
|---|---|---|
| `SLACK_WEBHOOK_URL` | Both preview + post scripts in Dynatrace UI | Incoming Webhook URL (same one that returned `ok`) |
| `DRY_RUN` | Both scripts (keep them matching) | `true` until a Run posts what you expect |
| `TEAMS_WEBHOOK_URL` | Optional, both scripts | Teams webhook if you have one; else leave `""` |

## WF-B task chain

```
extract-problem
  → preview-pagerduty
  → trigger-pagerduty
  → notify-slack-webhook   (optional; skips if URL empty)
```

| Setting | Where | What you put |
|---|---|---|
| Minimum duration | Trigger UI | **30 minutes** |
| `PD_ROUTING_KEY` | preview + trigger scripts | Test service Events API v2 key |
| `DRY_RUN` | PD scripts + Slack note script | `true` first |
| `SLACK_WEBHOOK_URL` | notify-slack-webhook only | Same webhook as WF-A, or leave empty |

## After import (order)

1. **Rotate if exposed** — If the webhook URL sat in a screenshot, editor, or chat, revoke it in Slack and create a new one. Paste only the new URL into Dynatrace.
2. Import both YAMLs into Dynatrace **Workflows**.
3. WF-A: set `SLACK_WEBHOOK_URL` in **preview-slack-webhook** and **post-slack-webhook**.
4. Keep `DRY_RUN = true` → **Run** workflow → check preview result.
5. Set `DRY_RUN = false` → Run again → confirm message in `#test-channel`.
6. Turn trigger **on** only after a good test (and narrow categories if needed).
7. WF-B: set **30m**, `PD_ROUTING_KEY`, test with `DRY_RUN true`, then optional Slack URL.

## Security (do this)

| Do | Do not |
|---|---|
| Paste URL only inside Dynatrace task editors | Put the URL in YAML committed to Adocs/git |
| Revoke a URL that appeared on screen | Reuse a leaked URL “because curl worked” |
| Keep `#test-channel` until proven | Point prod channel before DRY_RUN false test |

## Data flow map

```
Davis problem CREATED/ACTIVE
  → WF-A extract → build chat_message
  → preview (URL set? DRY_RUN?)
  → POST hooks.slack.com  {"text": chat_message}
  → #test-channel

Same problem still ACTIVE ≥ 30m
  → WF-B preview PD → POST events.pagerduty.com
  → optional POST same Slack webhook (short “paged” note)
```

## Related files

| File | Role |
|---|---|
| `11-wfa-ai-notify-slack-webhook.workflow.yaml` | Import this for Slack webhook WF-A |
| `11-wfb-30m-escalate-pagerduty.workflow.yaml` | Import this for WF-B |
| `../7-slack-incoming-webhook-wfa/` | How you created the webhook |
| `../8-slack-webhook-url-use-safely/` | Rotate / secret rules |
| `11.sh` | Copy + git one-liners (you run) |

## Commands

See [11.sh](./11.sh).
