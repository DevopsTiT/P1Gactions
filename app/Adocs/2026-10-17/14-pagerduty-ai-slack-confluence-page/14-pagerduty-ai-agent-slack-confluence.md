# PagerDuty AI Agent on Slack

> **Audience:** SRE / on-call and PagerDuty admins who need PagerDuty AI (Advance) in Slack.

> **Safety:** Use a **test** PagerDuty Service first. Fact-check every AI answer. Do not auto-run remediations on production.

---

## Decision tree

```
Want PagerDuty AI in Slack?
 Have PagerDuty Advance / PD Reliability Platform AI?
   NO  → ask Sales / admin for Advance; agents stay dark
   YES → Admin maps Slack workspace (Integrations → Extensions → Slack)
        → Link your PD user to Slack
        → AI → AI Settings → Assistant and AI Agents Configuration
        → Chat Integrations: Slack Connected (or Update required → optional scopes)
        → Toggle Slack On
        → Enable agents: Paige/SRE, Scribe, Shift, Insights
        → Test in a TEST service channel — not prod on-call
 Slack shows Not Connected?
   → Install Slack | PagerDuty integration first
 Slack shows Update required?
   → Approve optional scopes (channel history) for better AI summaries
 Old "PagerDuty Advance" Slack app still installed?
   → Use the main PagerDuty Slack app; uninstall Advance app after scopes work
```

---

## Short takeaway

| Question | Answer |
| --- | --- |
| What is it? | PagerDuty AI (also called **Advance**) chats and agents inside the **PagerDuty Slack app**. |
| Who can turn it on? | Admin, Global Admin, or Account Owner in PagerDuty; Slack workspace admin for app install. |
| Where do you enable it? | **AI → AI Settings → Assistant and AI Agents Configuration**. |
| How do you talk to it? | `@PagerDuty` in a channel, Slack side panel, or `/pd scribe`. |
| Safe first test? | Dedicated test Service whose escalation pages only you. |

---

## Summary

PagerDuty AI on Slack is not a separate mystery bot. Connect the normal PagerDuty Slack app, turn Slack on under AI Settings, enable the agents you need, link your user, then ask questions in an incident channel. Fact-check every AI answer before you act on production.

---

## Words you need first

| Word | What it means | Why you care |
| --- | --- | --- |
| PagerDuty AI / Advance | Paid AI add-on (or included on Reliability Platform). | Without it, agent toggles do nothing. |
| Slack app | Official PagerDuty app in your Slack workspace. | Where `@PagerDuty` and `/pd` live. |
| AI Assistant | Chatbot for summaries and questions. | Main ask surface. |
| AI Agent | Paige/SRE, Scribe, Shift, Insights. | Each does a different job. |
| Optional scopes | Extra Slack permissions (channel history). | Better AI summaries from channel talk. |
| Linked account | Slack user tied to PagerDuty user. | Needed for DMs, Shift, some actions. |
| Incident channel | Channel tied to a service or open incident. | Best place to ask. |

---

## What you get in Slack

| Piece | What it does |
| --- | --- |
| AI Assistant | Answers `@PagerDuty …` |
| Paige (SRE Agent) | Triage, root-cause ideas, runbook steps |
| Scribe Agent | Bridge transcript / summary (`/pd scribe`) |
| Shift Agent | Coverage / OOO help (needs linked user) |
| Insights Agent | Analytics questions; some Slack DMs |
| Slack side panel | Private 1:1 Assistant (paid Slack) |
| Proactive messages | Optional auto insights / catch-up |

---

## Roles needed

| Place | Role |
| --- | --- |
| PagerDuty | Admin, Global Admin, or Account Owner |
| Slack | Workspace admin or owner |
| You | Linked PD ↔ Slack user |

---

## Part A — One-time setup (admin)

### Step 1 — Map Slack to PagerDuty

1. PagerDuty: **Integrations → Extensions**.
2. Open the **Slack** tile.
3. **Add Workspace** → pick workspace → **Allow**.
4. Confirm bot is present and `/pd` works.

Guide: [Slack integration](https://docs.pagerduty.com/integrations/slack-integration-guide)

### Step 2 — Link your personal accounts

1. Click **Link Account** if shown.
2. Or complete `/pd` link flows in Slack.
3. Confirm Slack identity matches your on-call PagerDuty user.

### Step 3 — Connect PagerDuty AI to Slack

1. **AI → AI Settings**.
2. Tab **Assistant and AI Agents Configuration**.
3. Under **Chat Integrations**, check Slack:

| Status | What to do |
| --- | --- |
| Not Connected | Finish Slack \| PagerDuty install (Step 1). |
| Update required | Enable **optional scopes** (channel conversation; not threads). |
| Connected | Good. |

4. Toggle **Slack** to **On**.
5. Optional **Configure**:

| Option | Effect |
| --- | --- |
| Proactive Incident Insights | Context / symptoms when incident triggers |
| Proactive Incident Summarization | Catch-up for new members; post-resolve summary |

Guide: [PagerDuty AI](https://support.pagerduty.com/main/docs/pagerduty-advance)

### Step 4 — Enable each AI agent

| Agent | Turn on for |
| --- | --- |
| Paige (SRE Agent) | Live triage |
| Scribe Agent | Bridge notes |
| Shift Agent | Coverage help |
| Insights Agent | Analytics |

No permission? Click **Request to Admin**.

### Step 5 — Optional Slack side panel

1. Paid Slack plan + extra scopes.
2. Slack **Preferences → Navigation**.
3. **App agents & assistants** → check **PagerDuty**.

### Step 6 — Old Advance Slack app

Use the main **PagerDuty** Slack app. Uninstall the retired **PagerDuty Advance** Slack app after AI scopes work.

---

## Part B — Connect a channel

1. In Slack: `/pd connect`
2. Choose PagerDuty account.
3. Connect a **service** or **team**.
4. Notification style:

| Style | Meaning |
| --- | --- |
| Responder | Ack, resolve, full actions |
| Stakeholder | Updates without full controls |

Use a **test** service for first demos.

---

## Part C — How to use agents

### AI Assistant

```
@PagerDuty What is the current status of this incident?
@PagerDuty Catch me up
@PagerDuty What are likely root causes?
```

Or use the **PagerDuty AI side panel** for a private chat.

### Paige / SRE Agent

| Action | How |
| --- | --- |
| Triage | **SRE Agent Triage** or `@PagerDuty …` |
| Runbook | Upload small `.md` / `.txt` when prompted |
| Past incidents | `@PagerDuty Analyze past incidents` |
| Remediation | Approve or decline — do not auto-run on prod |

### Scribe Agent

1. Incident-linked channel.
2. `/pd scribe` or **Add Scribe Agent to meeting**.
3. Confirm meeting URL (include passcode) → **Add**.
4. Or leave auto-launch on under Scribe **Configure**.

### Shift / Insights

Ask with `@PagerDuty …` after accounts are linked. Prefer a test schedule first.

---

## Part D — Safety and checks

| Rule | Why |
| --- | --- |
| Test Service first | Avoids paging real on-call |
| Fact-check AI | Output can be wrong |
| Confirm remediations | Humans own blast radius |
| Optional scopes | AI may read channel history (not threads) |

### Health check

| Check | Pass if |
| --- | --- |
| `/pd` | Slash commands respond |
| AI Settings Slack = On | Toggle enabled |
| Agents Enabled | Paige / Scribe / … on |
| `@PagerDuty` | Bot answers in test channel |

---

## Result checklist

| Phase | Do |
| --- | --- |
| Admin once | Map Slack → link users → Slack On → enable agents |
| Team | `/pd connect` test service |
| Daily use | `@PagerDuty` / `/pd scribe` / side panel |
| Never skip | Test service + human confirm |

---

## Data flow

```
PagerDuty incident / service
  → Slack channel
  → Human: @PagerDuty / /pd scribe / side panel
  → PagerDuty AI (Advance)
  → Answer in Slack
  → Human fact-checks → ack / resolve / act
```

---

## Slack commands

```
/pd connect
/pd scribe
@PagerDuty Catch me up
@PagerDuty What are some likely root causes?
@PagerDuty Analyze past incidents
```

---

## Official docs

- [Slack integration](https://docs.pagerduty.com/integrations/slack-integration-guide)
- [PagerDuty AI](https://support.pagerduty.com/main/docs/pagerduty-advance)
- [Scribe Agent](https://docs.pagerduty.com/ai-automation/advance/scribe-agent)

---

## Document control

| Field | Value |
| --- | --- |
| Source | CursorFiles 2026-10-17 seq 4 |
| Confluence paste | Prefer `.wiki` via Insert → Markup → Confluence Wiki |
