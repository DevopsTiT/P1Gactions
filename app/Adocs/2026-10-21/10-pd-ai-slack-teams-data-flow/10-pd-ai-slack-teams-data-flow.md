# PagerDuty AI Slack Teams Data Flow

```
AI dark / Not Connected in Chat Integrations?
 → Step 0 license? → ask PD admin (Advance / Reliability Platform AI)
 → Step 1 chat app missing? → install Slack and/or Teams PD app
 → Step 2 AI Off? → AI Settings → turn chat On + enable agents
 → SRE not linked? → Link Account in Slack/Teams
 → still silent? → connect test channel → create test incident → @PagerDuty
```

| Key point | Detail |
|---|---|
| What this is | PagerDuty AI answers inside the normal PD Slack / Teams apps |
| What it is not | Dynatrace Hub Slack Connection or a custom webhook bot |
| Setup order | License → connect chat app → turn AI On → link your user → test channel |
| Runtime idea | Incident lives in PagerDuty; chat is the window; AI reads PD + chat context |

## Summary

PagerDuty AI does not replace PagerDuty. The chat app is a remote control: incidents still open in PagerDuty, and AI replies in Slack or Teams after admins connect the app and turn AI on.

## Two pictures to paste into Confluence

Use both. The first is **setup** (how pieces get wired). The second is **runtime** (what happens on an incident).

### A) Setup data flow (admin + SRE)

```
[PagerDuty account]
   |  Step 0: AI license OK (/ai page works)
   v
[PD Integrations]
   |  Step 1a: Slack workspace Allow  →  /pd works
   |  Step 1b: Teams app + permissions Allow
   v
[PD AI Settings → Chat Integrations]
   |  Step 2: status Connected + On
   |  Agents: Enabled (Scribe / Triage / …)
   v
[Each SRE]
   |  Link PD account ↔ Slack/Teams user
   v
[Test channel]
      /pd connect  (or Teams equivalent)
      → ready for runtime flow below
```

| Step | Who | What gets connected | Done when |
|---|---|---|---|
| 0 License | PD admin | PD account ↔ AI product | `/ai` and AI Settings are usable |
| 1 Chat app | PD + Slack/M365 admin | PD ↔ Slack workspace and/or Teams tenant | `/pd` (Slack) or PD bot (Teams) responds |
| 2 AI On | PD admin | Chat Integrations status On; agents Enabled | Status is not “Not Connected” |
| 3 Link user | Each SRE | Your PD user ↔ your chat user | You can use AI commands as yourself |
| 4 Channel | SRE / responder | PD service/channel mapping | Test channel shows PD messages |

### B) Runtime data flow (incident day)

```
Something breaks
  → Monitor / Dynatrace / etc. (optional upstream)
  → PagerDuty incident created (or updated)
  → PD posts / updates in connected Slack or Teams channel
  → You ask AI in that channel
        examples: @PagerDuty Catch me up
                  /pd scribe
                  @PagerDuty What are some likely root causes?
  → PagerDuty AI (Advance) reads incident + allowed chat context
  → AI reply appears in the same channel
  → You fact-check
  → Ack / escalate / resolve / run your runbook in PagerDuty
```

Plain English: **PagerDuty is the source of truth for the incident. Slack/Teams is where people talk. AI is a helper that reads both and answers in chat.**

### C) Who talks to whom (one-line map)

```
Dynatrace / other tools  --create/update-->  PagerDuty incident
PagerDuty                --notify-------->  Slack channel  and/or  Teams channel
Human in chat            --ask----------->  @PagerDuty / /pd …
PagerDuty AI             --answer-------->  same Slack / Teams thread
Human                    --act----------->  PagerDuty (ack, assign, resolve)
```

## Common mix-ups

| People think | What is true |
|---|---|
| PD AI is a separate Slack app | It uses the normal **PagerDuty** Slack / Teams app |
| Connecting Dynatrace Hub Slack = PD AI ready | Different path. Hub Slack is for Dynatrace workflows, not PD AI |
| AI replaces on-call judgment | AI suggests; you still verify and act in PagerDuty |
| One admin click finishes everything | License, chat install, AI On, and each user link are separate |

## Chat Integrations status cheat sheet

| Status you see | Meaning | Next action |
|---|---|---|
| Not Connected | Chat app not finished in Step 1 | Finish Slack Allow and/or Teams install |
| Update required / optional permissions | App needs more scopes for AI | Approve (for example Slack channel history, Teams optional perms) |
| Connected + Off | App linked but AI not enabled for chat | AI Settings → turn that chat On |
| Connected + On | Ready for users | Link accounts + connect a test channel |

## Roles (from your Confluence page)

| Role | Why you need them |
|---|---|
| PagerDuty Admin / Global Admin / Account Owner | AI Settings and chat mapping |
| Slack workspace admin | Install or reauthorize the PagerDuty app |
| Microsoft 365 / Teams admin | Allow PagerDuty Teams app + permissions |
| SRE | Link your own PD user to chat; run the test |

## Confluence paste block (compact)

Copy from the fence below into the Confluence page under Summary (or as a new “Data flow” section).

```
h2. Data flow

h3. Setup (wire once)

{code}
PagerDuty (license OK)
  → Connect Slack workspace and/or Teams app
  → AI Settings → Chat Integrations = Connected + On
  → Enable agents (Scribe / Triage / …)
  → Each SRE: Link Account
  → Test channel: /pd connect (or Teams equivalent)
{code}

h3. Runtime (every incident)

{code}
Incident opens in PagerDuty
  → Message appears in Slack and/or Teams channel
  → Responder asks @PagerDuty / /pd scribe / Catch me up
  → PagerDuty AI answers in the same chat
  → Responder fact-checks → acts in PagerDuty (ack / resolve)
{code}

*PagerDuty holds the incident. Chat is the window. AI is the helper in that window.*
```

## Data flow map

```
SETUP:
  PD license → Slack/Teams PD app → AI Chat Integrations On → user link → channel

RUNTIME:
  Event → PD incident → chat notify → human asks AI → AI reply → human acts in PD

NOT THIS PATH:
  Dynatrace Hub Slack Connection / Incoming Webhook  (WF-A chat)  ≠  PagerDuty AI
```

## Related files

| File | Role |
|---|---|
| Confluence page `04 PagerDuty AI Integration with Slack Teams` | Your live doc (Steps 0–2) |
| `10-pd-ai-slack-teams-data-flow.wiki` | Confluence Wiki markup paste |
| `0-pic.md` | Short pic |
| `10.sh` | Optional git sync one-liners |

## Commands

See [10.sh](./10.sh). None required to understand the flow.
