# How To Create Teams Webhook

```
Need a URL so Dynatrace can post to Teams?
 → Open the target Teams channel → … → Workflows
 → Template: Send webhook alerts to a channel
 → Add workflow → copy HTTP POST URL
 → Test with curl {"text":"…"}
 → Paste URL only into Dynatrace TEAMS_WEBHOOK_URL (not git)
 → Allowlist the Power Automate / logic.azure.com host in External requests
 Old “Connectors → Incoming Webhook” missing?
 → Expected — use Workflows instead
```

| Key point | Detail |
|---|---|
| What a Teams webhook is | An HTTPS URL; POST JSON → message appears in a channel |
| Current way to create it | Teams **Workflows** app (Power Automate), not old Office 365 Connectors |
| For WF-A | Same idea as Slack: `TEAMS_WEBHOOK_URL` + `fetch` POST `{"text":"…"}` |

## Summary

In Microsoft Teams, create a **Workflow** from the channel that listens for a webhook, then copy the URL. Dynatrace (or curl) POSTs JSON to that URL. Treat the URL like a password — paste only in Dynatrace, never in git.

## Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Channel | Chat room inside a Team | Where the message shows |
| Workflows app | Teams automation (Power Automate) | Where new webhooks are created |
| Webhook URL | Secret HTTPS address | Anyone with it can post to the channel |
| `{"text":"…"}` | Simple JSON body | Works for many templates and for WF-A |

---

## Steps — create the webhook (recommended)

1. Open **Microsoft Teams**.  
2. Go to the **Team** and **channel** you want (use a test channel first).  
3. Next to the channel name, click **⋯** (More options).  
4. Choose **Workflows**.  
5. Pick a channel template, usually:

   - **Send webhook alerts to a channel**  
   - or **Post to a channel when a webhook request is received** (wording varies)

6. Give it a clear name, e.g. `Dynatrace WF-A test`.  
7. Sign in / confirm the Microsoft account (must be allowed to post in that team).  
8. Confirm **Team** + **Channel**.  
9. Select **Add workflow** / **Save**.  
10. **Copy the HTTP POST URL** shown in the dialog.

If you miss the URL: open **Workflows** app → your workflow → **Edit** → expand the trigger **When a Teams webhook request is received** → copy URL.

### Who can create it

| You need | Why |
|---|---|
| Member of the Team (not guest-stuck) | Auth for the workflow |
| Permission to use Workflows / Power Automate | Org may block it — ask M365 admin |
| Channel where posting is allowed | Otherwise the action fails |

---

## Test with curl (you run)

Replace with your URL (do not commit the real URL):

```
curl -X POST -H "Content-Type: application/json" -d "{\"text\":\"WF-A Teams webhook test\"}" "YOUR_TEAMS_WEBHOOK_URL_HERE"
```

**Pass:** a message appears in that Teams channel.

Some templates expect Adaptive Card JSON. If `{"text":"…"}` does nothing, open the workflow’s **Post** action and map the trigger body, or ask your admin which payload the template expects. Many “Send webhook alerts” templates accept simple text.

---

## Use in Dynatrace WF-A

Same pattern as Slack Incoming Webhook:

| Setting | Where | Value |
|---|---|---|
| `TEAMS_WEBHOOK_URL` | `preview-slack-webhook` and `post-slack-webhook` scripts (both) | Paste URL in **Dynatrace UI only** |
| `DRY_RUN` | Both scripts | `false` when ready to send |
| HTTP call | Already in fixed workflow | `await fetch(TEAMS_WEBHOOK_URL, { method:"POST", … body: JSON.stringify({ text: m.chat_message }) })` |

Also: **Dynatrace → Settings → External requests** → allow the host from your URL (often something like `*.logic.azure.com` or `*.api.powerplatform.com` — copy the host from the URL you got).

---

## Path from scratch (if template missing)

1. Teams left rail → **Apps** / **View more apps** → **Workflows**.  
2. **Create** → **Create from blank**.  
3. Trigger: **When a Teams webhook request is received**.  
4. Who can trigger: **Anyone** (for Dynatrace/server posts) unless your security team requires stricter.  
5. Action: **Post card in chat or channel** (or Post message).  
6. Post in → **Channel** → pick team/channel.  
7. Map message body from the webhook (often trigger body / text).  
8. **Save** → copy HTTP POST URL from the trigger.

---

## Security

| Do | Do not |
|---|---|
| Paste URL only in Dynatrace script / secret store | Put URL in YAML, Adocs, git, Confluence |
| Use a **test** channel first | Point prod channel before curl works |
| Revoke/disable the workflow if the URL leaks | Reuse a leaked URL |

---

## Two Dynatrace paths (do not mix up)

| Path | What it is | When |
|---|---|---|
| Hub **Microsoft Teams Connection** | OAuth; workflow Hub “Send Teams message” | Preferred if admin allows Dynatrace Teams app |
| **Webhook URL** (this guide) | HTTP POST like Slack Incoming Webhook | Fallback / same style as your Slack WF-A |

See also: `../6-how-to-connect-teams-to-dynatrace/` for Hub Path 1.

## Data flow map

```
Teams channel → … → Workflows → webhook template
  → copy HTTP POST URL
  → curl / Dynatrace fetch POST {"text": chat_message}
  → message in that channel
```

## Related files

| File | Role |
|---|---|
| `25-how-to-create-teams-webhook.md` | This guide |
| `../6-how-to-connect-teams-to-dynatrace/` | Hub connection path |
| `../23-wfa-wfb-new-workflows/` | WF-A with `TEAMS_WEBHOOK_URL` |
| `25.sh` | Mirror + sample curl (placeholder URL) |

## Commands

See [25.sh](./25.sh).
