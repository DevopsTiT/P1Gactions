# WFA Dry Run Skipped No Slack

```
Workflow green but no new Slack message?
 → Open post-slack-webhook Result
 → reason = DRY_RUN_true and skipped = true?
      → Yes: set DRY_RUN = false in preview + post scripts (same value)
      → Paste SLACK_WEBHOOK_URL in both if missing
      → Run again → check #test-channel
 → reason = preview_not_ready?
      → Fix problems[] (usually missing URL)
 → Only old "WF-A webhook test" in channel?
      → That was curl; workflow never POSTed yet while DRY_RUN true
```

| Key point | Detail |
|---|---|
| Why no post | `post-slack-webhook` returned `skipped: true`, `reason: DRY_RUN_true` |
| What that means | Practice mode — builds preview, does **not** call Slack |
| Proof in Slack | Only earlier curl message `WF-A webhook test` — not the P-24181366 text |

## Summary

Your run succeeded. The last task chose not to send because `DRY_RUN` is still `true`. Turn it off in **both** Slack script tasks, keep the webhook URL set, run again, then the Dynatrace problem text should appear in `#test-channel`.

## What your Result tab already shows

| Field | Value | Meaning |
|---|---|---|
| `skipped` | `true` | No HTTP POST to Slack |
| `reason` | `DRY_RUN_true` | Blocked by the dry-run switch |
| `would_post_slack` | `true` | It *would* post if dry-run were false |
| `preview_slack.text` | Problem P-24181366 message | Message body is ready |

## What to change (Dynatrace UI)

Open these **two** tasks and edit the script constants:

### 1) `preview-slack-webhook`

```
const DRY_RUN = false;
const SLACK_WEBHOOK_URL = "https://hooks.slack.com/services/…";  // your URL, UI only
```

### 2) `post-slack-webhook`

```
const DRY_RUN = false;
const SLACK_WEBHOOK_URL = "https://hooks.slack.com/services/…";  // same URL
```

Both tasks must use the **same** `DRY_RUN` and the **same** URL.

Then **Run** the workflow again (on-demand is fine).

## Expected after fix

| Check | Pass |
|---|---|
| `post-slack-webhook` Result | `skipped: false`, `slack.ok: true` (or response `ok`) |
| `#test-channel` | New message with `[Dynatrace] New problem P-24181366` (or similar) |

## Data flow map

```
DRY_RUN = true  → preview OK → post skips → Slack unchanged
DRY_RUN = false + URL set → POST {"text": chat_message} → #test-channel
```

## Related files

| File | Role |
|---|---|
| `../19-fix-wfa-result-api/` | Fixed WF-A YAML |
| `20.sh` | Mirror |

## Commands

See [20.sh](./20.sh). None required — change constants in the UI.
