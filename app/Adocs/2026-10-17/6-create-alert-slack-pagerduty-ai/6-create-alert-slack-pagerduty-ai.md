# Create Alert In Slack With PagerDuty AI

## Decision tree

```
Want an "alert" in #test-channel?
 Know this first: PagerDuty AI does NOT create the alert.
   Alert/incident is created in PagerDuty (or Dynatrace → PagerDuty)
   Slack only receives and discusses it
   AI (@PagerDuty / agents) helps after the incident exists

 Your workspace (from screen)
   App "slack to pagerduty" already installed
   Channels: #pagerduty (starred), #test-channel (private), #all-demo-dynatrace
   Trial Slack (~8 days left)

 Path
   1) Confirm PagerDuty Advance / AI is on for your PD account
   2) Link Slack user (shuge.kui.ose) to PagerDuty user
   3) Invite PagerDuty bot into #test-channel (private channels need invite)
   4) /pd connect → bind TEST PagerDuty service to #test-channel
   5) Create a test incident on that service (PD UI or Dynatrace test problem)
   6) Incident post appears in Slack → @PagerDuty / SRE Triage / /pd scribe
```

## Short takeaway

| Question | Answer |
|---|---|
| Can the AI agent create the Slack alert by itself? | No. It answers and helps on incidents that already exist. |
| What creates the alert? | A PagerDuty **incident** on a **service** connected to the channel. |
| What you already have | App **slack to pagerduty** in the Demo trial workspace. |
| What you must do in `#test-channel` | Invite the bot, then `/pd connect` a test service. |
| Best first channel | `#test-channel` or `#pagerduty` with a **test** PD service only. |

## Summary

In your screenshot, Slack is ready enough (PagerDuty-related app is listed). Next you connect `#test-channel` to a PagerDuty service, fire a **test** incident, then use PagerDuty AI in that channel. Dynatrace (you also have `#all-demo-dynatrace`) can open the PD incident; Slack + AI are the chat layer.

## Investigation

### What your screen shows

| Item | Value |
|---|---|
| Workspace | Demo… trial Slack |
| You | `shuge.kui.ose` |
| Current channel | `#test-channel` (private / lock icon) |
| Useful channels | `#pagerduty`, `#all-demo-dynatrace` |
| Apps | `slack to pagerduty` already under Apps |

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| Incident | PagerDuty’s alert object (triggered / acked / resolved). | What Slack posts about. |
| Service | PD object that receives events and pages people. | What `/pd connect` binds to a channel. |
| `/pd connect` | Slack slash command to link channel ↔ service/team. | Required before alerts land in `#test-channel`. |
| PagerDuty AI / Advance | AI Assistant + agents in Slack. | Helps after the incident appears. |
| Private channel | Lock icon; bots are not in until invited. | Easy reason “nothing happens” in `#test-channel`. |

## Result

### Step 0 — Correct expectation

```
Dynatrace problem / Events API / "Create incident" in PD
  → PagerDuty Service creates Incident
  → Slack channel (via connection) shows the alert card
  → You: @PagerDuty … or SRE Triage or /pd scribe
```

PagerDuty AI does **not** replace the service or the routing key.

### Step 1 — Prerequisites in PagerDuty (web)

1. Log into the PagerDuty account that should own this demo.
2. Confirm you have **Admin** (or ask admin) for Slack mapping + AI.
3. Confirm **AI → AI Settings → Assistant and AI Agents Configuration**:
   - Slack shows **Connected** or **Update required** (approve optional scopes if asked).
   - Slack toggle **On**.
   - Enable agents you want (Paige/SRE, Scribe, …).
4. Create a **test** Service, for example `poc-slack-pd-ai-test`.
5. Escalation policy: page **only you** (or a demo user), never prod on-call.

### Step 2 — Link your Slack user

1. In Slack, open the **slack to pagerduty** / PagerDuty app home, or run a `/pd` command that prompts link.
2. Complete **Link Account** so `shuge.kui.ose` maps to your PagerDuty user.
3. Without this, AI DMs / some agent actions fail.

### Step 3 — Fix private channel access (`#test-channel`)

Because `#test-channel` is private:

1. Open `#test-channel`.
2. Channel details → **Integrations** / **Add apps** (wording varies).
3. Add **PagerDuty** (the same app as `slack to pagerduty`).
4. Or type `/invite` and pick the PagerDuty bot if your workspace allows it.

If the bot is not in the channel, `/pd connect` and alerts will not work there.

Optional: do the first demo in public `#pagerduty` if inviting apps to private channels is blocked on the trial.

### Step 4 — Connect the channel to a PagerDuty service

In `#test-channel` (after the bot is present), type:

```
/pd connect
```

Then in the modal:

| Field | What to choose |
|---|---|
| PagerDuty account | Your demo / trial PD account |
| Connect service or team | `poc-slack-pd-ai-test` (test service) |
| Notification type | **Responder** (so you can ack / resolve from Slack) |

Confirm. You should see a success message that this channel is connected.

Also connect `#pagerduty` the same way if you want a dedicated PD channel.

### Step 5 — Create the alert (incident)

Pick **one** way:

#### Option A — Create incident in PagerDuty UI (simplest)

1. PagerDuty → Incidents → **New Incident** (or Create Incident).
2. Service = your test service.
3. Title e.g. `Slack PD AI test from shuge`.
4. Create / Trigger.
5. Return to `#test-channel` — the incident card should appear.

#### Option B — From Dynatrace (fits `#all-demo-dynatrace`)

1. Ensure Dynatrace problem notification / workflow posts to that **same** PagerDuty service (routing key / Events API).
2. Open a **test** problem or run a safe test event.
3. PD incident opens → Slack gets the alert in the connected channel.

Do not point this test at a production service routing key.

#### Option C — Events API (if you already use it)

Send a trigger event to the test service integration key. Only if you already know that key and keep it out of chat/git.

### Step 6 — Use PagerDuty AI on that alert

Once the incident message is in `#test-channel`:

```
@PagerDuty Catch me up
@PagerDuty What are some likely root causes?
@PagerDuty What should I do first?
```

| Agent action | How |
|---|---|
| SRE / Paige triage | Click **SRE Agent Triage** on the incident card if shown, or ask with `@PagerDuty` |
| Scribe on a bridge | `/pd scribe` (needs meeting URL) |
| Private help | PagerDuty AI side panel (if enabled on paid Slack) |

Fact-check AI answers before any production action.

### Step 7 — If nothing appears in Slack

| Symptom | Check |
|---|---|
| `/pd` unknown | App not installed for you, or wrong workspace |
| `/pd connect` fails | Bot not in private channel; or PD↔Slack not mapped |
| Incident in PD, silent Slack | Channel not connected to that service; wrong account |
| Bot posts but `@PagerDuty` ignores AI | AI Slack toggle Off; Advance not licensed; user not linked |
| Only in `#pagerduty`, not `#test-channel` | You connected the other channel only |

## Data flow map

```
Your Slack (Demo trial)
  #test-channel (private) ──invite bot──► /pd connect ► PD test service
  #pagerduty
  app: slack to pagerduty
         ▲
         │ incident card + AI replies
         │
PagerDuty test service ◄── trigger ── PD UI / Dynatrace / Events API
         │
         ▼
PagerDuty AI (Advance) ◄── @PagerDuty / SRE Triage / /pd scribe
```

## Related files

| File | Purpose |
|---|---|
| `6-create-alert-slack-pagerduty-ai.md` | This guide for your workspace |
| `0-pic.md` | Decision tree |
| `1-investigation.md` | Screenshot notes |
| `2-result.md` | Checklist |
| `3-glossary.md` | Terms |
| `6.sh` | Git one-liners (not run) |
| 2026-10-17 seq 4 | General PagerDuty AI on Slack setup |

## Commands

Type these in Slack (`#test-channel` after bot invite). Not shell.

```
/invite @PagerDuty
/pd connect
@PagerDuty Catch me up
@PagerDuty What are some likely root causes?
/pd scribe
```

See `6.sh` for git only. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/6-create-alert-slack-pagerduty-ai
git commit -m "create alert slack pagerduty ai for test-channel"
git push
```
