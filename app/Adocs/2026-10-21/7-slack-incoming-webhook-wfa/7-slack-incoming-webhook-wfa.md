# Slack Incoming Webhook WFA

## Decision tree

```
No Dynatrace app in Slack (only “slack to pagerduty” etc.)?
  → Path 2: Slack Incoming Webhook (this page)
  Create webhook on #test-channel → copy URL (secret)
  → WF-A: after build-chat-message → HTTP POST {"text": chat_message}
  Hub Slack later?
    → Optional upgrade to Connection; webhook still fine for tests
```

## Short takeaway

| Step | What you do |
|---|---|
| 1 | In Slack `#test-channel` create an **Incoming Webhook** |
| 2 | Copy the URL (`https://hooks.slack.com/services/...`) into a **workflow secret** |
| 3 | WF-A: HTTP POST `{"text":"<chat_message>"}` to that URL |
| 4 | Test → message appears in `#test-channel` |

## Summary

You do **not** need a Dynatrace Slack Marketplace app for WF-A. Bind an **Incoming Webhook** to `#test-channel`, store the URL as a secret, and have the workflow POST the same text `build-chat-message` already built. PagerDuty’s Slack app is unrelated.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Incoming Webhook | Slack URL that accepts a simple POST and posts into one channel | Works without Dynatrace bot app |
| Webhook URL | Secret like `https://hooks.slack.com/services/T…/B…/…` | Treat like a password |
| `chat_message` | Text from WF-A task `build-chat-message` | What you put in `{"text":…}` |

---

## Path 2 — Fallback: Slack Incoming Webhook (no Hub / no Dynatrace app)

Use when Hub Slack connector or Marketplace Dynatrace app is blocked. Fits your workspace: Apps show Slack + “slack to pagerduty”, channel `#test-channel` (private).

### A. Create the webhook in Slack

**Option A1 — From the channel (simple)**

1. Open Slack → **`#test-channel`**.  
2. Click the channel name → **Integrations** tab (or **Settings** → Integrations).  
3. **Add an app** → search **Incoming Webhooks**.  
4. If the org blocks it, ask Slack admin to allow **Incoming Webhooks**.  
5. **Add to Slack** → choose **`#test-channel`** → **Add Incoming Webhooks integration**.  
6. Copy **Webhook URL**.  
7. Optional: set a username/icon (e.g. `Dynatrace WF-A`).  
8. **Save**.

**Option A2 — From api.slack.com (if channel UI has no Incoming Webhooks)**

1. Open [https://api.slack.com/apps](https://api.slack.com/apps) → **Create New App** → From scratch.  
2. **Incoming Webhooks** → **On**.  
3. **Add New Webhook to Workspace** → select **`#test-channel`** → Allow.  
4. Copy the Webhook URL.  

Private channel: you must be a member of `#test-channel` (you already are).

### B. Store the URL (secret)

| Do | Do not |
|---|---|
| Dynatrace workflow **secret** / Connection secret / env the HTTP task reads | Paste into git, Confluence, chat, or the YAML committed to Adocs |
| Name e.g. `SLACK_WEBHOOK_URL` | Share the full URL in screenshots |

### C. Wire WF-A (after `build-chat-message`)

You can leave `emit-chat-payload` for debugging, and add a send task:

1. Open WF-A in Dynatrace **Workflows**.  
2. After **`build-chat-message`**, add **HTTP request** or **Run JavaScript** with `httpClient`.  
3. **Method:** `POST`  
4. **URL:** secret `SLACK_WEBHOOK_URL`  
5. **Headers:** `Content-Type: application/json`  
6. **Body:**

```json
{
  "text": "{{ result(\"build-chat-message\").chat_message }}"
}
```

Exact expression syntax depends on the HTTP action UI — goal is: body field `text` = output `chat_message`.

**JavaScript sketch** (if you use a JS task):

```javascript
import { execution } from '@dynatrace-sdk/automation-utils';
import { httpClient } from '@dynatrace-sdk/http-client';

export default async function () {
  const ex = execution();
  const m = await ex.result("build-chat-message");
  const url = /* read from workflow secret SLACK_WEBHOOK_URL */;
  const res = await httpClient.fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ text: m.chat_message })
  });
  return { status: res.status, ok: res.ok };
}
```

(Fill secret access the way your tenant documents — never hardcode the URL in the script if it will be committed.)

### D. Test

1. Keep workflow trigger inactive or use **Run** with a sample.  
2. Confirm a message appears in **`#test-channel`**.  
3. Then activate for real problems.

### E. Optional richer Slack layout later

```json
{
  "text": "Dynatrace problem summary",
  "blocks": []
}
```

Start with plain `text` only until it works.

---

## What you do **not** need for this path

| Not required | Why |
|---|---|
| Dynatrace app in Slack Marketplace | Webhook posts as Incoming Webhooks / your app name |
| Bot token `xoxb-…` | Webhook URL replaces it |
| Inviting a Dynatrace bot | Webhook is already bound to `#test-channel` |
| “slack to pagerduty” app | That is PagerDuty, not Dynatrace WF-A |

---

## Teams twin (same idea)

| Slack | Teams |
|---|---|
| Incoming Webhook on `#test-channel` | Incoming Webhook / Workflows webhook on test channel |
| POST `{"text":"…"}` | Often POST `{"text":"…"}` (some Workflow connectors differ) |

---

## Common failures

| Symptom | Fix |
|---|---|
| Cannot add Incoming Webhooks | Slack admin must allow the app / feature |
| 404 on POST | URL revoked or wrong; recreate webhook |
| 400 invalid_payload | Send JSON `{"text":"…"}` with `Content-Type: application/json` |
| No message | Wrong channel selected when creating webhook; recreate on `#test-channel` |
| URL leaked | Revoke webhook in Slack; create a new one; update secret |

## Result

| Done | Evidence |
|---|---|
| Webhook created | URL starts with `https://hooks.slack.com/services/` |
| Secret stored | Only in Dynatrace secret store |
| WF-A wired | HTTP/JS task after `build-chat-message` |
| Verified | Test text visible in `#test-channel` |

## Data flow map

```
#test-channel
  → Incoming Webhook URL (secret)
  → WF-A: build-chat-message
  → HTTP POST {"text": chat_message}
  → Message appears in #test-channel
```

## Related files

| File | Purpose |
|---|---|
| `7-slack-incoming-webhook-wfa.md` | This Slack webhook Path 2 |
| `7-slack-webhook-http-body.sample.json` | Sample POST body |
| `../6-how-to-connect-teams-to-dynatrace/` | Teams Path 2 twin |
| `../3-no-dynatrace-app-in-slack-marketplace/` | Why Marketplace is empty |
| `../2026-10-18/2-dt-ai-replace-pd-all-files/12-wfa-*.yaml` | WF-A template |
| `7.sh` | Git one-liners (not run) |

## Commands

See `7.sh`. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-21/7-slack-incoming-webhook-wfa
git commit -m "slack incoming webhook path for wfa"
git push
```
