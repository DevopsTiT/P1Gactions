# Slack Webhook URL Use Safely

## Decision tree

```
Got a Slack Incoming Webhook URL?
  Pasted in chat / screenshot / email?
    → YES: Revoke that webhook in Slack NOW → create a NEW URL
  Where to store the new URL?
    → Dynatrace workflow secret only (e.g. SLACK_WEBHOOK_URL)
  How to use in WF-A?
    → HTTP POST {"text": chat_message} to the secret URL
  Never?
    → git, Confluence, Daily Files, YAML committed to Adocs, Slack itself
```

## Short takeaway

| Topic | What to do |
|---|---|
| URL you showed in chat | **Revoke and recreate** — treat as leaked |
| Where the new URL lives | Dynatrace **secret** / Connection secret only |
| WF-A use | POST JSON `text` = `build-chat-message.chat_message` |
| This note | Contains **no** real webhook URL |

## Summary

A Slack Incoming Webhook URL is a password for posting into a channel. If it appears in a screenshot or chat, revoke it and make a new one. Put only the new URL into a Dynatrace workflow secret, then point WF-A’s HTTP task at that secret.

## Investigation

### 1 — Revoke the exposed URL (do this first)

1. Slack → [api.slack.com/apps](https://api.slack.com/apps) → the app that owns the webhook  
   **or** channel **Integrations** → Incoming Webhooks.  
2. **Remove** / deactivate the webhook you pasted.  
3. **Add New Webhook** → `#test-channel` again.  
4. Copy the **new** URL only into a password manager or Dynatrace secret UI — not into chat.

### 2 — Store in Dynatrace (not in YAML files)

| Place | OK? |
|---|---|
| Workflow **secret** named e.g. `SLACK_WEBHOOK_URL` | Yes |
| Hardcoded in a JS task that you will git-commit | No |
| Confluence / Daily Files / Adocs | No |

### 3 — WF-A HTTP task (after `build-chat-message`)

| Field | Value |
|---|---|
| Method | `POST` |
| URL | From secret `SLACK_WEBHOOK_URL` |
| Header | `Content-Type: application/json` |
| Body | `{"text": "<chat_message>"}` |

Use the expression picker so `text` comes from `result("build-chat-message").chat_message`.

### 4 — Quick verify (you run locally; do not log the URL)

Optional curl shape (replace URL yourself; do not paste URL into shared notes):

```
curl -X POST -H "Content-Type: application/json" -d "{\"text\":\"WF-A webhook test\"}" "YOUR_NEW_WEBHOOK_URL_HERE"
```

Pass = message in `#test-channel`.

## Result

| Done | Evidence |
|---|---|
| Old URL revoked | Cannot post with the leaked URL |
| New URL in Dynatrace secret only | Not in git/chat |
| WF-A test | Message in `#test-channel` |

## Data flow map

```
(new) Incoming Webhook URL
  → Dynatrace secret SLACK_WEBHOOK_URL
  → WF-A HTTP POST {"text": chat_message}
  → #test-channel
```

## Related files

| File | Purpose |
|---|---|
| `8-slack-webhook-url-use-safely.md` | Safety + how to use (no real URL) |
| `../7-slack-incoming-webhook-wfa/` | Full webhook Path 2 steps |
| `8.sh` | Git one-liners (not run) |

## Commands

See `8.sh`. None have been run. Do not put real webhook URLs in shell history shared files.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-21/8-slack-webhook-url-use-safely
git commit -m "slack webhook url use safely"
git push
```
