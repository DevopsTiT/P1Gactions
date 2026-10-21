# Slack Webhook Paste In Dynatrace Only

```
Have a working Incoming Webhook URL?
 → Paste ONLY inside Dynatrace task scripts (SLACK_WEBHOOK_URL = "…")
 → Never put it in YAML / Adocs / git / Confluence / chat files
 → URL was on screen? → after paste works, revoke + create new URL + update Dynatrace
 → Also allowlist hooks.slack.com under External requests
```

| Key point | Detail |
|---|---|
| Where to put URL | Dynatrace Workflow UI → each script’s `const SLACK_WEBHOOK_URL = "…"` |
| Where **not** to put it | Workflow YAML in git, Adocs, Daily Files, screenshots shared to others |
| Why | Anyone with the URL can post to your `#test-channel` |

## Summary

Do **not** bake the Slack webhook into committed workflow files. Open each workflow in Dynatrace and paste the URL into the script constants listed below. Keep `DRY_RUN = false` and use global `fetch` (see seq 21).

## Where to paste (all Slack-using workflows)

### WF-A — AI notify Slack via Incoming Webhook

Tasks (same URL in both):

| Task | Constant |
|---|---|
| `preview-slack-webhook` | `const SLACK_WEBHOOK_URL = "<paste here>";` |
| `post-slack-webhook` | `const SLACK_WEBHOOK_URL = "<paste here>";` |

Also set in both:

```
const DRY_RUN = false;
```

### WF-B — 30m escalate PagerDuty (+ optional Slack note)

| Task | Constant |
|---|---|
| `notify-slack-webhook` | `const SLACK_WEBHOOK_URL = "<paste here>";` |
| (same task) | `const DRY_RUN = false;` when you want a real Slack note |

Leave empty (`""`) if you do not want WF-B to post to Slack.

## Paste shape (Dynatrace UI only)

```
const SLACK_WEBHOOK_URL = "https://hooks.slack.com/services/…";
```

Never commit that line with a real path after `/services/`.

## Checklist

```
[ ] External requests → hooks.slack.com allowed
[ ] WF-A preview-slack-webhook → URL + DRY_RUN false
[ ] WF-A post-slack-webhook → same URL + DRY_RUN false
[ ] WF-B notify-slack-webhook → URL (optional) + DRY_RUN false
[ ] Run WF-A → #test-channel shows Dynatrace problem text
[ ] Rotate webhook if it was saved in a local text file / screenshot
```

## Data flow map

```
Your notepad / screenshot (secret)
  → paste into Dynatrace script only
  → fetch(SLACK_WEBHOOK_URL) at runtime
  → #test-channel

YAML / git / Adocs
  → SLACK_WEBHOOK_URL = ""   (placeholder only)
```

## Related files

| File | Role |
|---|---|
| `../21-fix-wfa-global-fetch/` | Workflows with `fetch` + empty URL placeholder |
| `../19-fix-wfa-result-api/` | `result()` API fix |
| `22.sh` | Mirror (no secrets) |

## Commands

See [22.sh](./22.sh). Do not put the real URL in shell history files you commit.
