# Slack Bot Token How To Get

## Decision tree

```
Need Slack bot token for Dynatrace connector?
  Prefer Hub OAuth “Add connection”?
    → YES: no token paste; Slack Allow stores it in Connection
  Form asks for Bot User OAuth Token?
    → Slack api.slack.com/apps → your app → OAuth & Permissions → Bot User OAuth Token
  Want a “sample” token to test?
    → Use PLACEHOLDER only (never a real key from the internet)
    → Real post needs a token from YOUR workspace
 Never commit xoxb-… to git / Confluence
```

## Short takeaway

| Question | Answer |
|---|---|
| Can anyone give you a working sample bot token? | **No** — it only works for the workspace that created it |
| What does one look like? | Starts with `xoxb-` (Bot User OAuth Token) |
| Placeholder for docs / forms | `xoxb-YOUR-WORKSPACE-BOT-TOKEN` or `xoxb-************` |
| Preferred for Dynatrace | Hub **Add connection** (OAuth) so you never paste the token into YAML |
| Where to copy a real one | Slack app → **OAuth & Permissions** → **Bot User OAuth Token** |

## Summary

A Slack bot token is a secret for your workspace. There is no universal sample that can post to your channels. Prefer Dynatrace Hub OAuth. If a form requires a token, create/install a Slack app and copy **Bot User OAuth Token** (`xoxb-…`) yourself; store it only in Dynatrace Connections.

## Investigation

### Placeholder format (not a real key)

Use only as a shape reminder (do **not** invent numeric fake tokens — GitHub push protection flags them):

```
<Bot User OAuth Token from Slack app OAuth page — starts with xoxb->
```

Or write in docs: “Bot token prefix is xoxb” without a full sample string.

### Token types (do not mix up)

| Prefix | What it is | For Dynatrace Slack send? |
|---|---|---|
| `xoxb-` | **Bot** User OAuth Token | Yes — usual choice |
| `xoxp-` | User (person) token | Usually not for bot posts |
| `xapp-` | App-level token | Different use (sockets, etc.) |
| Webhook URL | `https://hooks.slack.com/services/...` | Alternative Path 3 — not an `xoxb` token |

---

## Preferred: no token paste (Dynatrace Hub OAuth)

1. Dynatrace → **Hub** → **Slack**.  
2. **Add connection** → Slack **Allow**.  
3. Dynatrace stores the credential inside the **Connection**.  
4. WF-A picks the connection name — you never put `xoxb-` in the workflow YAML.

Use this when Marketplace search failed but Hub Slack still works.

---

## If the connector form asks for a Bot token

### How to get a real `xoxb-` from your Slack

1. Open [https://api.slack.com/apps](https://api.slack.com/apps) (workspace admin may be required).  
2. **Create New App** → From scratch → name it (e.g. `dynatrace-wfa-test`) → pick workspace.  
3. **OAuth & Permissions** → **Scopes** → Bot Token Scopes. Minimum often needed to post:
   - `chat:write`
   - `channels:read` (and/or `groups:read` for private channels)
   - Invite/join as needed: `channels:join`  
4. **Install to Workspace** → **Allow**.  
5. Copy **Bot User OAuth Token** (`xoxb-…`).  
6. Paste **only** into Dynatrace Connection / secret store — not into git, Confluence, or chat.  
7. In Slack: invite that **app/bot** into `#test-channel`.  
8. Test send from Dynatrace.

### Rotate if leaked

Slack app → OAuth → reinstall / revoke tokens; create a new token; update Dynatrace Connection.

---

## Webhook alternative (no `xoxb` at all)

If you cannot create a bot app:

1. Slack → Incoming Webhooks → channel → copy URL.  
2. WF-A HTTP POST `{"text":"..."}` to that URL.  

That URL is also a secret — treat like a password.

---

## Safety

| Rule | Why |
|---|---|
| No shared “sample” working token | Would be someone else’s (or fake) workspace |
| Never commit `xoxb-` / webhook URLs | Credential leak |
| Test channel first | Limits blast radius |
| Prefer Connection OAuth | Token not sitting in workflow scripts |

## Result

| Goal | Done when |
|---|---|
| Placeholder understood | You use `xoxb-YOUR-…` only as documentation |
| Real token obtained | Copied from your Slack app OAuth page into Dynatrace Connection |
| WF-A posts | Message appears in `#test-channel` |

## Data flow map

```
Slack api.slack.com/apps
  → Create app + bot scopes
  → Install → Bot User OAuth Token (xoxb-…)
  → Dynatrace Connection (secret store)
  → WF-A notify-slack → #test-channel

OR Hub OAuth: Dynatrace Hub Slack → Allow → Connection (no manual xoxb)
OR Webhook: hooks.slack.com URL → HTTP POST
```

## Related files

| File | Purpose |
|---|---|
| `4-slack-bot-token-how-to-get.md` | This guide |
| `../3-no-dynatrace-app-in-slack-marketplace/` | Hub / webhook when Marketplace empty |
| `../2-how-to-get-wfa-wfb-info/` | All WF-A/WF-B values |
| `4.sh` | Git one-liners (not run) |

## Commands

See `4.sh`. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-21/4-slack-bot-token-how-to-get
git commit -m "slack bot token how to get"
git push
```
