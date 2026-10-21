# Investigation

## Why replace

Hub Slack Connection needs a bot token / Marketplace app. Incoming Webhook already works with the same POST your curl used.

## Proof you already have

| Check | Evidence |
|---|---|
| Webhook accepts POST | Terminal returned `ok` |
| Channel binding | `#test-channel` showed **WF-A webhook test** |

## What the new WF-A does differently

| Old path | New path |
|---|---|
| `notify-slack` Hub connector + Connection | `preview-slack-webhook` → `post-slack-webhook` HTTP |
| Bot token inside Connection | Incoming Webhook URL in script (Dynatrace UI only) |
