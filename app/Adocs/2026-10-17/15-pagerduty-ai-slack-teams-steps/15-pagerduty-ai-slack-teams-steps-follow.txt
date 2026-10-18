# PagerDuty AI Slack Or Teams Steps

## Decision tree

```
Want PagerDuty AI in chat?
 Have Advance / Reliability Platform AI?
   NO  → ask admin / Sales first
   YES → pick Slack and/or Teams
        → Admin connects chat app(s)
        → AI Settings: chat = Connected, toggle On
        → Enable agents (Paige, Scribe, Shift, Insights)
        → You: Link Account in that chat
        → /pd connect (Slack) or connect service (Teams)
        → Test service only → @PagerDuty / agent commands
 Both Slack and Teams?
   YES → OK; pick one primary incident channel; avoid double-page
 Slack/Teams shows Not Connected?
   → Admin must install/map the app (you cannot finish alone)
```

## Short takeaway

| Step group | What you do |
|---|---|
| 0 | Confirm PagerDuty AI (Advance) is licensed |
| 1 | Admin connects Slack and/or Teams |
| 2 | AI Settings → chat On → enable agents |
| 3 | Link your user in Slack and/or Teams |
| 4 | Connect a **test** service to a channel |
| 5 | Open a test incident → use `@PagerDuty` / Scribe / Triage |
| 6 | Fact-check AI; never auto-run prod remediations |

## Summary

PagerDuty AI runs inside the normal PagerDuty Slack or Teams app. Admin connects the chat, you link your account, connect a test service to a channel, then talk to the bot. Same agents work in both chats; command wording differs slightly.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| Advance / PagerDuty AI | Paid AI features (Paige, Scribe, Shift, Insights, Assistant) |
| Connected | Chat integration ready on `AI → AI Settings` |
| Link Account | Your Slack/Teams identity = your PagerDuty user |
| Paige | SRE Agent (triage / RCA help) |
| Scribe | Meeting transcript / summary agent |

---

## Steps (do in order)

### Step 0 — License check

1. Open `https://<your-subdomain>.pagerduty.com/ai` (example: `axa-life-japan.pagerduty.com/ai`).
2. If you have no AI Settings / agents stay dark → ask admin for **Advance** or Reliability Platform AI.

### Step 1 — Admin: connect chat app(s)

**Slack**

1. PagerDuty → **Integrations → Extensions → Slack**.
2. **Add Workspace** → **Allow**.
3. Confirm `/pd` works in Slack.

**Microsoft Teams**

1. Microsoft admin allows the PagerDuty Teams app + required permissions.
2. Install **Microsoft Teams | PagerDuty**.
3. Accept optional permissions for PagerDuty AI if asked.

You may connect **both** Slack and Teams.

### Step 2 — Admin: turn AI on for that chat

1. PagerDuty → **AI → AI Settings**.
2. Tab **Assistant and AI Agents Configuration**.
3. Under **Chat Integrations**:

| Status | Action |
|---|---|
| Not Connected | Finish Step 1 |
| Update required / optional permissions | Approve scopes (Slack channel history; Teams optional perms) |
| Connected | Good |

4. Toggle **Slack** and/or **Microsoft Teams** to **On**.
5. Optional: **Configure** proactive insights / summarization.
6. Under **AI Agents**, enable what you need:

| Agent | Purpose |
|---|---|
| Paige (SRE) | Triage, root cause ideas, next steps |
| Scribe | Bridge notes / transcript |
| Shift | On-call coverage help |
| Insights | Analytics questions |

No permission? **Request to Admin**.

### Step 3 — You: link your account

**Slack:** open PagerDuty app / banner → **Link Account**, or complete `/pd` link flow.

**Teams:** in a channel with the bot, run the link-user flow (often `@PagerDuty linkUser` — follow the prompt in your tenant).

Do this once per chat app you use.

### Step 4 — Connect a test channel to a service

**Slack**

```
/pd connect
```

Pick account → **test** service or team → **Responder** (for demos).

Private channels: invite the PagerDuty bot first.

**Teams**

Connect the PagerDuty service/team to the Teams channel using your tenant’s connect command or PD Teams UI (same idea: channel ↔ service).

Use a **test** service that pages **only you**.

### Step 5 — Create a test incident

1. PagerDuty → create incident on the **test** service  
   **or** Dynatrace/Events API to that test routing key.
2. Confirm the incident card appears in the Slack or Teams channel.

### Step 6 — Use PagerDuty AI in the channel

**Slack**

```
@PagerDuty Catch me up
@PagerDuty What are some likely root causes?
@PagerDuty Analyze past incidents
/pd scribe
```

- **Paige:** click **SRE Agent Triage** if shown, or ask with `@PagerDuty`.
- **Side panel (optional, paid Slack):** Preferences → Navigation → App agents → PagerDuty.

**Teams**

```
@PagerDuty Catch me up
@PagerDuty What are some likely root causes?
```

- Scribe often: `@PagerDuty advance scribe` (confirm exact command in your tenant).
- Link/connect commands may use `@PagerDuty …` rather than `/pd`.

### Step 7 — Safety checks

| Rule | Why |
|---|---|
| Test service first | Avoids waking prod on-call |
| Fact-check AI | Output can be wrong |
| Confirm remediations | Humans own blast radius |
| One primary chat for live talk | If both Slack and Teams are on, pick one home thread |

### Step 8 — Health check

| Check | Pass |
|---|---|
| `/ai` chat card | Connected + On |
| Agents | Enabled |
| User linked | Your chat user = PD user |
| Channel connected | Test service mapped |
| Bot answers | `@PagerDuty Catch me up` gets a reply |

---

## Slack vs Teams cheat sheet

| Action | Slack | Teams |
|---|---|---|
| Connect channel | `/pd connect` | `@PagerDuty` connect / Teams PD UI |
| Ask AI | `@PagerDuty …` | `@PagerDuty …` (sometimes `@PagerDuty advance …`) |
| Scribe | `/pd scribe` | `@PagerDuty advance scribe` (verify locally) |
| Side panel | Paid Slack option | Not the same feature |
| Shift DMs | Stronger Slack docs | Weaker / limited |

## Result

| Phase | Done when |
|---|---|
| Admin | Slack and/or Teams Connected + On; agents Enabled |
| You | Account linked; test channel connected |
| Demo | Test incident → AI reply in chat |
| Prod later | Same steps with real service only after test OK |

## Data flow map

```
Incident on PD service
  → Slack and/or Teams channel (connected)
  → You: @PagerDuty / Scribe / Triage
  → PagerDuty AI (Advance)
  → Answer in chat
  → You fact-check → ack / resolve / act
```

## Related files

| File | Purpose |
|---|---|
| `15-pagerduty-ai-slack-teams-steps.md` | This step list |
| `../4-pagerduty-ai-agent-slack-instructions/` | Slack-deep guide |
| `../14-pagerduty-ai-slack-confluence-page/` | Confluence paste |
| `../7-pagerduty-ai-slack-not-connected/` | If status = Not Connected |
| `../10-add-teams-along-with-slack/` | Using both chats |
| `15.sh` | Git one-liners (not run) |

## Commands

Slack (type in Slack):

```
/pd connect
/pd scribe
@PagerDuty Catch me up
@PagerDuty What are some likely root causes?
@PagerDuty Analyze past incidents
```

Teams (type in Teams; confirm exact Scribe wording in your tenant):

```
@PagerDuty Catch me up
@PagerDuty What are some likely root causes?
@PagerDuty advance scribe
```

See `15.sh` for git only. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/15-pagerduty-ai-slack-teams-steps
git commit -m "pagerduty ai slack teams steps"
git push
```
