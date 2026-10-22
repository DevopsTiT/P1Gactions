# PD AI Alert Reaction Capabilities Reply

```
Colleague asks: did you try PD AI on an alert?
 → License / Chat Integrations Connected + On?
 → No → enable first (see 2026-10-21/10-pd-ai-slack-teams-data-flow)
 → Yes → create test incident → ask @PagerDuty Catch me up / Scribe
 → Reply with: how it reacts | how it helps | capabilities
```

| Key point | Detail |
|---|---|
| Question | How does PagerDuty AI react to an alert, how it helps, and what it can do |
| Short answer | Alert becomes a PD incident; AI does not page you — it helps you understand and communicate after the page |
| How it helps | Faster catch-up, drafts, less copy-paste of timeline and status |
| Honest limit | Suggests only; human still acks, escalates, and resolves in PagerDuty |

## Summary

Davesh asked whether you tried **PagerDuty AI** on an alert, how it helps, and what it can do. Plain English: monitoring (for example Dynatrace) still creates the PagerDuty incident and pages on-call. **PD AI** sits on top of that incident and helps responders in Slack/Teams with summaries, triage hints, status drafts, meeting notes (Scribe), and post-incident drafts. It is not a second pager.

---

## Ready reply (paste to Teams)

```
Hi Davesh — short answers:

1) How PD AI reacts to an alert
- The alert / event still creates (or updates) a normal PagerDuty incident and pages on-call as usual.
- PD AI does not replace that page. After the incident exists, you (or the channel) can ask the PagerDuty bot / AI Assistant in Slack or Teams — e.g. “Catch me up”, likely causes, status draft, Scribe notes.
- So the reaction is: incident first → AI assists in chat on that incident context.

2) How it will be helpful
- Faster catch-up when you join mid-incident
- Less manual writing for status updates and post-incident notes
- Pulls context from the incident + allowed chat / meeting transcript (Scribe), so less hunting across tools
- Still needs human fact-check before we act or send stakeholder updates

3) Main capabilities (PagerDuty AI / Advance)
- AI Assistant in Slack / Teams (summaries, troubleshooting prompts)
- Agents (e.g. Scribe for meeting + chat notes)
- AI status updates
- AI-assisted post-incident reviews
- (Related but different product area) Event Intelligence / AIOps: alert grouping, noise reduction, probable origin — that acts earlier on the alert stream

I have not finished a live “create test alert → ask AI” walkthrough in our tenant yet / I will do a test incident in the PD-connected channel and share screenshots next.
(Replace the last line with what is true for you.)
```

---

## How PD AI reacts to an alert (beginner view)

| Stage | What happens | Who / what |
|---|---|---|
| 1 Signal | Monitor fires (Dynatrace problem, etc.) | Upstream tool |
| 2 Page | PagerDuty creates/updates an **incident** and notifies on-call | Classic PD behavior |
| 3 Chat | Incident appears in connected Slack/Teams channel | PD chat app |
| 4 Ask AI | Responder asks `@PagerDuty` / Catch me up / Scribe | Human |
| 5 Assist | AI answers using incident + allowed chat/meeting context | PagerDuty AI |
| 6 Act | Ack, escalate, resolve, run runbook | Human in PagerDuty |

**What it does not do:** invent a separate alert path, auto-ack by default, or replace on-call judgment.

---

## How it is helpful

| Benefit | What it means | Why you care |
|---|---|---|
| Faster situational awareness | Summarizes what happened so far | You join late and still get oriented |
| Less writing toil | Drafts status updates and PIR text | You stay focused on fixing |
| Shared context | Uses incident log + chat / Scribe notes | Fewer “what did we already try?” loops |
| Guided next questions | Suggests diagnostic angles | Useful when the service is unfamiliar |

---

## Capabilities checklist

| Capability | What it is | Alert / incident angle |
|---|---|---|
| AI Assistant | Chat helper in Slack / Teams | After incident opens: catch-up, likely causes, troubleshooting prompts |
| Scribe Agent | Meeting + chat transcription for incidents | Enriches summaries and later PIR |
| AI Status Updates | Drafts stakeholder updates from PD + chat | Push-button draft; you edit and send |
| AI Post-Incident Review | Drafts PIR narrative and follow-ups | After resolve; editable |
| AI Agents | Assist with repetitive connected-tool tasks | Depends what admins enable |
| Event Intelligence (AIOps) | Group / suppress / route / probable origin | Acts on the **alert stream** before or as incidents form — related but not the same as chat AI |

License note: PagerDuty AI is on **PD Reliability Platform**, or labeled **PagerDuty Advance** as an add-on on some plans. If Chat Integrations show Not Connected, AI will not answer in chat until setup is done.

---

## Quick test plan (if you have not tried yet)

| Step | Action | Pass when |
|---|---|---|
| 1 | Open PD AI Settings → Chat Integrations | Connected + On for Slack and/or Teams |
| 2 | Link your PD user in the chat app | Commands work as you |
| 3 | Create a low-priority test incident on a safe service | Message appears in test channel |
| 4 | Ask `@PagerDuty Catch me up` (or Teams equivalent) | AI reply with incident summary |
| 5 | Optional: `/pd scribe` or ask for a status draft | Usable draft you can edit |

Docs: [PagerDuty AI](https://docs.pagerduty.com/ai-automation/advance), [Scribe Agent](https://docs.pagerduty.com/ai-automation/advance/scribe-agent), [AI & Automation overview](https://docs.pagerduty.com/ai-automation).

## Data flow map

```
Alert / Dynatrace problem
  → PagerDuty incident + page (unchanged)
  → Slack / Teams channel notify
  → Human asks PD AI (@PagerDuty / Catch me up / Scribe)
  → AI reply in chat
  → Human fact-checks → acts in PagerDuty

Separate earlier path (Event Intelligence):
  Many alerts → group / suppress / route → fewer or richer incidents
```

## Related files

| File | Role |
|---|---|
| `2026-10-21/10-pd-ai-slack-teams-data-flow/` | Setup + runtime wiring for Slack/Teams |
| Your Confluence `04 PagerDuty AI Integration with Slack Teams` | Tenant steps |
| `18.sh` | Dual-write |

## Commands

See [18.sh](18.sh). No CLI required for the reply.
