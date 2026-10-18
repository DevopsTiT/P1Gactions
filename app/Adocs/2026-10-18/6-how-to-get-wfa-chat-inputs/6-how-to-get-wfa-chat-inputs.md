# How To Get WFA Chat Inputs

## Decision tree

```
Need Slack/Teams inputs for WF-A notify tasks?
  No Dynatrace Slack app yet?
    → Install Slack app → create Connection in Dynatrace → invite bot to channel
  No Dynatrace Teams app yet?
    → Install Teams app → create Connection → pick team/channel
  Connection exists but blank in workflow?
    → Open task → Connection dropdown → pick the named connection
  Channel unknown?
    → Use test channel name (#…) or channel ID from Slack/Teams UI
  Message field?
    → Do not invent text; reference build-chat-message.chat_message
```

## Short takeaway

| # | Input | How you get it |
|---|---|---|
| 1 | Slack connection | Create once in Dynatrace **Settings → Connections** (or Hub Slack app) after installing the Slack app |
| 2 | Slack channel | Create or pick a Slack channel; invite the Dynatrace bot; type `#name` or channel ID in the task |
| 3 | Teams connection | Same idea for Microsoft Teams app + Dynatrace Connection |
| 4 | Teams channel | Pick team + channel in the Teams send task (or channel id your connector expects) |
| 5 | Message field | Expression from the previous workflow task — not a secret you look up |

## Summary

A **connection** is Dynatrace’s saved login to Slack or Teams (token lives there). A **channel** is where the bot posts. The **message** is already built by `build-chat-message`; you only point the send task at that result. You never paste the Slack bot token into the workflow YAML.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Connection | Named credential in Dynatrace for Slack or Teams | Workflow task picks it from a dropdown |
| Hub app | Dynatrace Marketplace app (Slack / Teams connector) | Provides the “Send message” action |
| Bot / app | The Dynatrace app installed in Slack or Teams | Must be invited to the channel or it cannot post |
| Channel | Slack `#name` or Teams channel under a team | Where humans read the AI / problem text |
| Expression | `{{ result("task-name").field }}` | Pulls output from an earlier workflow task |

---

## 1 — Slack connection (how to get it)

### What it is

A Dynatrace object that stores the Slack app credentials. The workflow only selects the **name** of that connection.

### How to create / find it

1. In **Slack** (workspace admin may be required):
   - Install the **Dynatrace** Slack app (or the official Dynatrace Slack integration your company uses).
   - Complete Allow / OAuth so Dynatrace can post messages.
2. In **Dynatrace**:
   - Open **Hub** (or App) → find **Slack** / Slack connector.
   - Or go to **Settings → Connections** (wording varies by version) → **Slack**.
   - Click **Add connection** / **Connect**.
   - Finish the auth flow (opens Slack; Approve).
   - Give it a clear name, for example `slack-ops-test`.
3. Later in the workflow task `notify-slack` → **Connection** dropdown → pick `slack-ops-test`.

### What you do **not** put in the workflow

| Do not paste into YAML | Where it actually lives |
|---|---|
| Slack bot token (`xoxb-…`) | Inside the Dynatrace Connection (secret store) |
| User password | Never |

### If the dropdown is empty

| Check | Action |
|---|---|
| Hub Slack app not installed | Install from Dynatrace Hub |
| Connection never created | Add connection and re-auth |
| Wrong environment | Confirm you are in the same Dynatrace tenant where you imported WF-A |

---

## 2 — Slack channel (how to get it)

### What it is

The place the message appears, for example `#test-channel`.

### How to get a safe test channel

1. In Slack: create a channel (or reuse one), e.g. `#test-channel` or `#dt-ai-test`.
2. Open the channel → **Integrations** / members → **Add apps** → invite the **Dynatrace** bot.
3. Copy the channel name (`#test-channel`).
4. In the workflow **notify-slack** task → **Channel** field → enter `#test-channel`.

### If the connector wants a channel ID instead of `#name`

1. In Slack (desktop): open the channel → click the channel name → scroll to bottom → copy **Channel ID**.  
   Or: right-click channel → View channel details → Channel ID.
2. Paste that ID into the Channel field if the Dynatrace action docs say “channel ID”.

### Common failure

| Symptom | Likely cause |
|---|---|
| Workflow succeeds but no message | Bot not invited to the channel |
| Permission / not_in_channel | Invite the Dynatrace app to that channel |

---

## 3 — Teams connection (how to get it)

### What it is

Same idea as Slack: Dynatrace stores Teams credentials as a named **Connection**.

### How to create / find it

1. **Microsoft 365 / Teams admin** (often required once):
   - Allow the **Dynatrace** Teams app for your tenant.
2. In **Teams**:
   - Apps → search Dynatrace → Add (to a team you use for tests).
3. In **Dynatrace**:
   - Hub → **Microsoft Teams** connector (or Settings → Connections → Teams).
   - **Add connection** → sign in / consent with an account that can post to the test team.
   - Name it, for example `teams-ops-test`.
4. In workflow task `notify-teams` → **Connection** → pick `teams-ops-test`.

### What you do not put in the workflow

Tenant secrets and client secrets stay in the Connection, not in the YAML.

---

## 4 — Teams channel (how to get it)

### What it is

Which **Team** and **Channel** receive the post (for example Team `SRE-Test` → Channel `alerts-test`).

### How to get it

1. In Teams, open (or create) a **test** team and channel, e.g. `dt-ai-test`.
2. Ensure the Dynatrace app is added to that **team**.
3. In the Dynatrace **notify-teams** task:
   - Pick **Team** from the dropdown (populated via your connection).
   - Pick **Channel** from the dropdown.
4. If your connector uses IDs:
   - Teams → channel `…` menu → **Get link to channel** → the link contains team and channel ids, or use the connector’s picker (preferred).

### Tip

Use a **test** channel first. Prod ops channels come after the message format looks right.

---

## 5 — Message field (how to get it)

### What it is

Not a password or channel name. It is an **expression** that pulls text the workflow already built.

### Where the text comes from

```
extract-problem
  → build-chat-message   (creates chat_message)
  → notify-slack / notify-teams   (send that text)
```

### What to type in the Message box

Use one of these (Dynatrace expression syntax; UI may offer a picker):

```
{{ result("build-chat-message").chat_message }}
```

Or, if you still have the placeholder task and want its `message` field:

```
{{ result("emit-chat-payload").message }}
```

Prefer **`build-chat-message`.chat_message** once real notify tasks are in place.

### How to find the field name in the UI

1. Open the workflow.  
2. Click task **build-chat-message** → look at **Result** / output schema after a test run: you should see `chat_message`.  
3. In **notify-slack** → Message → use **Insert expression** / browse previous task results → select `chat_message`.

### Optional: AI text inside that message

If you add **Prompt generative AI** and map output into `ai_summary`, `build-chat-message` already prefers that text. You still send the same `chat_message` field — you do not paste the AI reply by hand.

---

## End-to-end order (do this once)

| Step | Action |
|---|---|
| A | Install Dynatrace Slack app; create Slack **Connection** in Dynatrace |
| B | Create `#test-channel`; invite Dynatrace bot |
| C | Install Dynatrace Teams app; create Teams **Connection** |
| D | Create test Teams channel; add Dynatrace app to that team |
| E | Import WF-A; add `notify-slack` + `notify-teams` tasks |
| F | Connection dropdowns → pick your connections |
| G | Channel fields → test Slack + Teams channels |
| H | Message → `{{ result("build-chat-message").chat_message }}` |
| I | Run a test problem; confirm posts; then activate |

## Only Slack or only Teams?

| You have | Fill |
|---|---|
| Slack only | Rows 1, 2, 5 — skip Teams tasks or leave them inactive |
| Teams only | Rows 3, 4, 5 — skip Slack tasks |
| Both | Fill all five; same message to both |

## Result

| Input | You know you got it when |
|---|---|
| Slack connection | Named connection appears in the workflow dropdown |
| Slack channel | Test post appears in that channel |
| Teams connection | Named connection appears in the dropdown |
| Teams channel | Test post appears in that Teams channel |
| Message expression | Sent text matches `chat_message` from a test run |

## Data flow map

```
Slack admin: install Dynatrace app
  → Dynatrace: create Slack Connection (token stored here)
  → Slack: invite bot to #test-channel
  → WF-A notify-slack: pick Connection + #test-channel
       Message = result(build-chat-message).chat_message

Teams admin: allow Dynatrace app
  → Dynatrace: create Teams Connection
  → Teams: add app to test team/channel
  → WF-A notify-teams: pick Connection + channel
       Message = same chat_message
```

## Related files

| File | Purpose |
|---|---|
| `6-how-to-get-wfa-chat-inputs.md` | This guide |
| `../4-wfa-wfb-inputs-needed/` | Full WF-A / WF-B input list |
| `../5-wfa-wfb-workflow-explain/` | What WF-A / WF-B do |
| `../2-dt-ai-replace-pd-all-files/12-wfa-…yaml` | WF-A template |
| `6.sh` | Git one-liners (not run) |

## Commands

See `6.sh`. None have been run. All setup is in Slack / Teams / Dynatrace UI.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-18/6-how-to-get-wfa-chat-inputs
git commit -m "how to get wfa chat inputs"
git push
```
