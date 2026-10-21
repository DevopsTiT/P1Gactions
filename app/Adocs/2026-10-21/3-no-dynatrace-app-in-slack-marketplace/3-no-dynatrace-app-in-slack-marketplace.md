# No Dynatrace App In Slack Marketplace

## Decision tree

```
Slack Marketplace search “dynatrace” → no Dynatrace app?
  Normal for many workspaces (app approval / listing / region)
  Do NOT install unrelated apps (e.g. Zenduty / Xurrent)

  Path 1 (preferred): Start in Dynatrace Hub → Slack connector → OAuth to Slack
  Path 2: Ask Slack admin to approve / allow Dynatrace app for the workspace
  Path 3 (works without Marketplace app): Slack Incoming Webhook → WF-A HTTP send

  Still blocked?
    → Admin: app allowlist, or use webhook / Teams only
```

## Short takeaway

| Question | Answer |
|---|---|
| Why no Dynatrace in Marketplace? | Often hidden by workspace **approved apps** policy, or you must install from **Dynatrace Hub**, not Slack search |
| Is Zenduty / Xurrent the Dynatrace app? | **No** — ignore that result |
| Correct first place to install? | **Dynatrace → Hub → Slack** (creates the Slack connection) |
| Fallback without any Slack “Dynatrace app”? | **Incoming Webhook** URL + workflow HTTP POST |
| WF-A still works? | Yes — Hub connector **or** webhook |

## Summary

You do not need to find “Dynatrace” in the Slack Marketplace for WF-A. Install or connect Slack **from Dynatrace Hub**, or use a Slack **Incoming Webhook**. Marketplace search failing is common on locked-down workspaces.

## Investigation

### Why Marketplace shows nothing useful

| Cause | What it means |
|---|---|
| Approved apps only | Your Slack org only shows apps an admin allowed; Dynatrace may not be on the list |
| Install-from-vendor flow | Dynatrace expects you to start in **Hub**, which then opens Slack OAuth |
| Wrong search hit | “Xurrent IMR (Zenduty)” is **not** Dynatrace — do not install it for this |
| Region / listing | Directory listing can differ; Hub path still works |

---

## Path 1 — Preferred: Dynatrace Hub → Slack (not Marketplace search)

### Steps

1. Open **Dynatrace** (same environment where you import WF-A).  
2. Go to **Hub** (Marketplace / Apps).  
3. Search **Slack** (or “Slack connector” / “Send message to Slack” — wording varies).  
4. **Install / Add** the Slack integration for Automations / Workflows.  
5. **Add connection** → browser opens Slack → **Allow** the workspace.  
6. Name the connection (e.g. `slack-ops-test`).  
7. In Slack: open your test channel → **Integrations / Add apps** → if Dynatrace (or the connected bot name) appears, invite it; if Hub used a bot name, invite that bot.  
8. In WF-A: add **Send Slack message** (or Hub Slack action) → pick **Connection** + **Channel**.

### How you know it worked

| Check | Pass |
|---|---|
| Dynatrace Connections | A Slack connection exists |
| Workflow task | Connection dropdown is not empty |
| Test | Manual/test run posts into `#test-channel` |

You may never see a nice “Dynatrace” tile in Slack Marketplace and still be fully connected.

---

## Path 2 — Ask Slack admin (if Hub OAuth is blocked)

Ask your Slack workspace admin for one of these:

| Ask | Why |
|---|---|
| Approve / allow the Dynatrace Slack app (or the app Hub requests) | OAuth can finish |
| Allow **Incoming Webhooks** for your workspace/channel | Path 3 works |
| Confirm you are allowed to install apps | Some users cannot add any app |

---

## Path 3 — Fallback: Incoming Webhook (no Dynatrace Marketplace app)

Use this when Hub Slack connector is unavailable but you can still create a webhook.

### Create the webhook in Slack

1. Slack → your **test** channel.  
2. Channel menu → **Integrations** → **Add an app** → search **Incoming Webhooks** (or open [api.slack.com/apps](https://api.slack.com/apps) → Create App → Incoming Webhooks → Add to workspace → pick channel).  
3. Copy the **Webhook URL** (`https://hooks.slack.com/services/...`).  
4. Store it as a **workflow secret** / connection secret — **never** commit it to git or Confluence.

### Use it from Dynatrace WF-A

Replace “Slack connector send” with an **HTTP** / JavaScript task that POSTs JSON:

```http
POST <WEBHOOK_URL>
Content-Type: application/json

{"text": "<chat_message from build-chat-message>"}
```

Conceptually after `build-chat-message`:

```
POST body: { "text": result("build-chat-message").chat_message }
```

Same idea for Teams: use a **Teams Incoming Webhook** / Workflow connector URL if Teams Hub app is also missing.

---

## What to do for your WF-A checklist now

| Original ask | Do this instead |
|---|---|
| “Install Dynatrace from Slack Marketplace” | **Skip** — use Path 1 Hub or Path 3 webhook |
| Slack connection | Created by Hub OAuth **or** replaced by webhook secret |
| Slack channel | Still use a **test** channel; invite bot **or** bind webhook to that channel |
| Message field | Still `{{ result("build-chat-message").chat_message }}` (connector) or same string in webhook `text` |

WF-B (PagerDuty) does **not** need any Slack app. Continue with PD routing key + 30m as before.

---

## Common mistakes

| Mistake | Fix |
|---|---|
| Installing Zenduty / Xurrent because search showed it | Unrelated — uninstall if you added it by mistake |
| Searching only in Slack Marketplace | Start in **Dynatrace Hub** |
| Pasting webhook URL into git / Confluence | Use workflow secret only |
| Expecting `@Dynatrace` like `@PagerDuty` AI | WF-A is **workflow post**, not PagerDuty Advance chat |

## Result

| Goal | Done when |
|---|---|
| Chat path without Marketplace Dynatrace tile | Hub Slack connection **or** webhook posts a test message |
| WF-A complete | Test problem → message in `#test-channel` |
| WF-B unaffected | Still only needs PD key + 30m |

## Data flow map

```
Wrong: Slack Marketplace search "dynatrace" → empty / wrong app

Right Path 1:
  Dynatrace Hub Slack → OAuth → Connection → WF-A Send message → channel

Right Path 3:
  Slack Incoming Webhook URL (secret)
    → WF-A HTTP POST { text: chat_message }
    → channel
```

## Related files

| File | Purpose |
|---|---|
| `3-no-dynatrace-app-in-slack-marketplace.md` | This guide |
| `../2-how-to-get-wfa-wfb-info/` | How to get all WF-A/WF-B values |
| `../1-wfa-wfb-fill-in-checklist/` | Fill-in checklist |
| `../2026-10-18/2-dt-ai-replace-pd-all-files/12-wfa-*.yaml` | WF-A template |
| `3.sh` | Git one-liners (not run) |

## Commands

See `3.sh`. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-21/3-no-dynatrace-app-in-slack-marketplace
git commit -m "no dynatrace app in slack marketplace paths"
git push
```
