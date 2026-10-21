# How To Connect Teams To Dynatrace

## Decision tree

```
Want Dynatrace → Microsoft Teams messages (WF-A)?
  Path 1 (preferred): Dynatrace Hub → Microsoft Teams → Add connection → consent
    → Add Dynatrace app to test Team → pick channel in workflow
  Path 1 blocked (admin / app not allowed)?
    → Ask M365 admin to allow Dynatrace Teams app
  Path 2 (fallback): Teams channel → Incoming Webhook / Workflows webhook URL
    → WF-A HTTP POST JSON to that URL
  Do NOT use only Settings → Problem notifications for WF-A Connection
```

## Short takeaway

| Step | What you do |
|---|---|
| 1 | (Admin) Allow Dynatrace app in Microsoft 365 / Teams if required |
| 2 | Dynatrace **Hub → Microsoft Teams** → install → **Add connection** |
| 3 | In Teams: add the app to your **test team** / channel |
| 4 | WF-A: `notify-teams` → pick **Connection** + **Team** + **Channel** |
| Fallback | Channel **Incoming Webhook** URL → workflow HTTP send |

## Summary

Connect Teams from **Dynatrace Hub** (OAuth connection), then use that connection inside **Workflows**. If Hub is blocked, use a Teams **Incoming Webhook**. This is separate from classic Problem notifications and from the Slack Marketplace search.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Hub | Dynatrace app store | Where you install the Teams connector |
| Connection | Saved Teams login in Dynatrace | WF-A dropdown picks this name |
| Team / channel | Where the message appears | Humans read the AI / problem text |
| Incoming Webhook | URL that accepts POST messages | Fallback if no Hub app |
| Consent | Admin or user Allow in Microsoft login | Without it, connection fails |

---

## Path 1 — Preferred: Dynatrace Hub → Teams connection

### A. Microsoft / Teams admin (often required once)

Ask your M365 admin if needed:

| Ask | Why |
|---|---|
| Allow the **Dynatrace** app for Teams in the tenant | Users can install / consent |
| Allow custom apps / third-party apps if policy blocks them | Hub OAuth can finish |

### B. In Dynatrace

1. Open the **same Dynatrace environment** where you import WF-A.  
2. Go to **Hub** (Apps / Marketplace).  
3. Search **Microsoft Teams** or **Teams**.  
4. Open the connector used by **Workflows / Automations** (send message to Teams).  
5. **Install** / enable if needed.  
6. **Add connection** (or **Connect**).  
7. Sign in with a Microsoft account that can post to the test team → **Accept** permissions.  
8. Name the connection, e.g. `teams-ops-test`.

### C. In Microsoft Teams

1. Create or open a **test** team (e.g. `SRE-DT-Test`).  
2. Create a channel (e.g. `dt-ai-test`).  
3. **Apps** → search Dynatrace (or the bot name the Hub connection created) → **Add to a team** → pick that test team.  
4. Confirm the app/bot is listed for the team.

If the app never appears in Teams store (same idea as Slack Marketplace), Hub connection may still work after admin allow — or use Path 2.

### D. In WF-A workflow

1. Import / open WF-A.  
2. Add **Send Microsoft Teams message** (Hub action; exact name varies).  
3. **Connection** → `teams-ops-test`.  
4. **Team** → your test team.  
5. **Channel** → `dt-ai-test`.  
6. **Message** → `{{ result("build-chat-message").chat_message }}`.  
7. Run a test problem → confirm the post in Teams.

### How you know Path 1 worked

| Check | Pass |
|---|---|
| Dynatrace Connections | Teams connection listed |
| Workflow dropdown | Connection / team / channel selectable |
| Teams channel | Test message visible |

---

## Path 2 — Fallback: Teams Incoming Webhook (no Hub app)

Use when Hub Teams connector or admin consent is blocked.

### Create webhook in Teams

1. Teams → open the **test channel**.  
2. Channel **⋯** → **Connectors** / **Manage channel** → **Apps** / **Workflows** (UI varies by Teams version).  
3. Add **Incoming Webhook** (or “Post to a channel when a webhook request is received” Workflow).  
4. Name it (e.g. `Dynatrace WF-A test`) → Create → **copy the URL**.  
5. Store URL as a **workflow secret** — never commit to git or Confluence.

### Send from Dynatrace WF-A

After `build-chat-message`, add an **HTTP** / JS task:

```http
POST <TEAMS_WEBHOOK_URL>
Content-Type: application/json

{"text": "<chat_message>"}
```

Some Teams Workflow connectors expect a slightly different JSON shape (e.g. Adaptive Card). If plain `text` fails, check the connector docs for the template you created; start with `{"text":"..."}`.

---

## Path 3 — Classic Problem notifications (optional, not WF-A)

Settings → Integration → **Problem notifications** → Add notification → **Microsoft Teams** (if listed) or Custom → webhook.

| Use | Not for |
|---|---|
| Simple “problem opened” ping by Alerting profile | Filling WF-A Hub **Connection** for AI workflow YAML |

---

## Permissions / consent (typical)

Exact scopes depend on the Dynatrace Teams app version. Expect Microsoft prompts for posting messages to teams/channels. Only accept with an account that may post to the **test** team.

---

## Common failures

| Symptom | Likely cause | Fix |
|---|---|---|
| Cannot Add connection | App blocked in tenant | M365 admin allow Dynatrace |
| Connection OK, no post | App not added to that Team | Add app to team; use correct channel |
| Dropdown empty in workflow | Wrong Dynatrace env / connector not installed | Same env as Hub install |
| Webhook 404 / 400 | Wrong URL or JSON body | Recreate webhook; try `{"text":"..."}` |
| Looking only in Teams app store | Same as Slack Marketplace gap | Start from **Dynatrace Hub** or webhook |

---

## Side by side with Slack

| Step | Teams | Slack |
|---|---|---|
| Start | Dynatrace Hub → Microsoft Teams | Dynatrace Hub → Slack |
| Fallback | Teams Incoming Webhook | Slack Incoming Webhook |
| WF-A task | notify-teams | notify-slack |
| Message | Same `chat_message` expression | Same |

You can enable **both**; pick one primary talk channel to avoid noise.

## Result

| Goal | Done when |
|---|---|
| Path 1 | Named Teams Connection + test post in channel |
| Path 2 | Webhook secret + HTTP task posts to channel |
| WF-A ready | `notify-teams` (or HTTP) uses `chat_message` |

## Data flow map

```
Path 1:
  M365 allow (if needed)
    → Dynatrace Hub Teams → Connection
    → Teams: add app to test team/channel
    → WF-A notify-teams → message

Path 2:
  Teams channel Incoming Webhook URL (secret)
    → WF-A HTTP POST { text: chat_message }
    → channel
```

## Related files

| File | Purpose |
|---|---|
| `6-how-to-connect-teams-to-dynatrace.md` | This guide |
| `../2-how-to-get-wfa-wfb-info/` | All WF-A/WF-B values |
| `../3-no-dynatrace-app-in-slack-marketplace/` | Same idea for Slack |
| `../5-problem-notifications-vs-workflow-slack-teams/` | Why not only Problem notifications |
| `../2026-10-18/2-dt-ai-replace-pd-all-files/12-wfa-*.yaml` | WF-A template |
| `6.sh` | Git one-liners (not run) |

## Commands

See `6.sh`. None have been run. Setup is in Teams / Dynatrace UI.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-21/6-how-to-connect-teams-to-dynatrace
git commit -m "how to connect teams to dynatrace"
git push
```
