# PagerDuty AI Agents Detailed

## Decision tree

```
What job do you need help with?
        │
        ├─ Active incident: triage / root cause / runbook / remediation?
        │     → SRE Agent (virtual responder)
        │
        ├─ Incident bridge: capture what people said / draft PIR notes?
        │     → Scribe Agent (meeting transcript + summary)
        │
        ├─ On-call schedule: OOO conflict / find coverage / override?
        │     → Shift Agent (schedule assistant)
        │
        └─ Ops health: MTTR trends / noisy teams / maturity tips?
              → Insights Agent (analytics Q&A + weekly nudges)
```

```
Prerequisites gate (all agents)
  Have PagerDuty Advance (add-on or AI Actions)?
    NO  → ask Sales / enable trial; agents will not work
    YES → Admin/Global Admin → AI → AI Settings
          → Assistant and AI Agents Configuration
          → Connect Slack and/or Teams
          → Toggle each agent Enabled
```

```
Dynatrace → PagerDuty stack (where agents sit)
  Dynatrace Problem
    → PD notification / Events API / Workflow connector
    → PD Incident (+ AIOps Event Orchestration optional)
    → Human on-call page
    → SRE Agent investigates alongside human
    → Scribe Agent records the bridge
    → Insights Agent learns weekly trends after the fact
    → Shift Agent keeps coverage healthy before the next page
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Official count | Exactly **4** named AI agents (Fall 2025 suite). Your “4 agents” belief matches product marketing. |
| The four | SRE Agent, Scribe Agent, Shift Agent, Insights Agent |
| Umbrella (not an agent) | **PagerDuty Advance** = platform + AI Actions budget + Assistant that routes to agents |
| Also not “the 4 agents” | Event Intelligence / noise reduction, Automation Digest, status-update drafts, AI-generated runbooks — useful Advance features, separate from the named agent suite |
| When you care | Dynatrace finds the problem; PD pages you; agents cut toil around triage, notes, coverage, and trends |

---

## Summary

PagerDuty’s public AI agent suite (announced Fall 2025, docs current through 2026) is four purpose-built agents under **PagerDuty Advance**. The **SRE Agent** is the one that acts like a virtual responder on live incidents. **Scribe** records bridges, **Shift** fixes on-call coverage gaps, and **Insights** answers analytics questions and sends weekly maturity tips. Enable them from **AI → AI Settings**, connect Slack/Teams, then use each in the channel or UI surfaces below.

---

## Main content

### What is not one of the four agents

| Name | What it is | Why you care |
| --- | --- | --- |
| PagerDuty Advance | Paid AI platform (credits or add-on on Professional / Business / Enterprise) | Agents live here; without Advance you cannot turn them on |
| Advance Assistant | Generative chat in Slack/Teams that routes questions to the right agent | Entry point in chat; not counted as a separate “agent” in the suite of four |
| Event Intelligence / AIOps | Alert grouping, correlation, Event Orchestration | Noise reduction before a human (or SRE Agent) ever sees the page |
| Status updates / PIR drafts / Automation Digest | Advance generative features | Save writing time; they consume AI Actions but are not the four named agents |

### The four agents at a glance

| Agent | What it is | When to use | How to enable / use (UI) | Detailed example scenario | POC tip |
| --- | --- | --- | --- | --- | --- |
| SRE Agent | Virtual responder that reads incident context, past incidents, runbooks, and connected logs, then suggests (and can run approved) remediations | Live P1/P2 triage when you need “what happened before?” and “what do I try first?” in minutes | Admin: AI → AI Settings → Assistant and AI Agents → toggle **SRE Agent** on. Optional: add Connectors (Grafana, Datadog, New Relic, CloudWatch, Confluence, GitHub). Use: Operations Console → incident → **SRE Agent** tab; or Incident Details → **SRE Agent** tab; or Slack `@pagerduty` / **SRE Agent Triage**; or MS Teams (Early Access). Virtual responder: Incident Workflow or Escalation Policy (EA) | Dynatrace pages “Checkout latency high.” On-call opens Slack incident channel, clicks **SRE Agent Triage**. Agent summarizes payload, finds three similar past incidents, points at a deploy change event, suggests the existing rollback workflow, and asks you to confirm before running it. | Upload one `.md` runbook for your test service first. Resolve the incident so memory saves. Cost: **4 AI Actions** per chat ask or nudge click. Ops Console needs **AIOps + Advance**. |
| Scribe Agent | Joins Zoom / Teams / Google Meet incident bridges, streams an enhanced transcript, posts a post-meeting summary | Every major incident bridge where people talk faster than anyone can type notes | Admin enables Scribe (US: manual toggle; EU: on by default). Configure Zoom captions / Teams lobby / Google Workspace as needed. Optional: disable auto-launch under **Configure**. Use: auto-launch when a conference URL is on the incident; or Incident Workflow “Add Scribe Agent”; or Slack `/pd scribe` / Teams `@PagerDuty advance scribe` → **Add Scribe Agent to meeting** | P1 war room on Zoom. Scribe joins, posts live transcript to `#inc-1234`, tracks join/leave. After hang-up it posts summary (decisions, action items, attendees). Later you ask Advance for a Post-Incident Review draft that already includes bridge context. | Link a real meeting URL with passcode. Someone must join within **15 minutes** or auto-join skips. Cap: **1 Scribe per meeting**, up to **10** concurrent meetings. Consumes AI Actions (roughly 6 per 30 min + 2 for final summary). |
| Shift Agent | Scheduling assistant that spots calendar conflicts on Level-1 schedules and helps request coverage / overrides | Before coverage gaps: vacation, doctor appointment, last-minute OOO overlapping primary on-call | Usually activates when Advance + Slack are on. Put the schedule you care about on **escalation Level 1**. Admin can enable Google Calendar Extension. Use in Advance chat: “I am on vacation June 13. Do I have a conflict?” then **Request coverage**. Candidates get notified; accept updates the schedule. | Primary on-call blocks Friday OOO on Google Calendar. Shift Agent DMs: conflict detected. Manager clicks **Request coverage**; two teammates get Slack asks; one accepts; schedule override is written without spreadsheet ping-pong. | Does **not** consume AI Actions. Only Level-1 schedules are watched (by design, less noise). Confirm Notification Rules for shift conflict and coverage request. |
| Insights Agent | Conversational analytics over Incidents / Services / Teams reports, plus weekly proactive maturity tips | After incidents: “are we getting noisier?” “which team blows MTTA?” before leadership reviews | Auto-on with Advance. Ask in public Slack `@pagerduty …` or Advance chat. Managers/Admins/Owners get weekly DMs with recommended platform settings (for example enable alert grouping). Unsubscribe from DMs without losing chat Q&A. | Team lead asks: “How has average time to resolve changed over the past 6 months for Payments?” Agent returns trend vs prior period. Weekly DM suggests turning on Dynamic Notifications for three noisy services; one click opens PD to apply. | Free of AI Actions. Link Slack ↔ PD user for proactive DMs. Start with one Team and one Service name you actually own so answers are checkable. |

### SRE Agent — deeper how-to

**What this is:** An AI site reliability helper tied to a PagerDuty **Service**. It builds **memory** (playbook scratchpad, customer runbooks, summaries, service profile) each time you resolve incidents.

**Why it matters:** The first 10 minutes of an incident are usually hunting docs and logs. The agent does that parallel work so humans decide, not dig.

| Surface | How you start | Good first questions |
| --- | --- | --- |
| Operations Console | AIOps → Operations Console → open incident → **SRE Agent** tab | “What are some likely root causes?” |
| Incident details | Open incident → right panel **SRE Agent** | “Analyze past incidents” |
| Slack | Incident channel → **SRE Agent Triage** or `@pagerduty …` | “List related incidents” |
| MS Teams | `@pagerduty …` (Early Access) | “What steps should I take first?” |

| Nudge / action | What it means |
| --- | --- |
| Upload / Update Runbook | Teach the agent your SOP for this service |
| Analyze Past / Related Incidents | Pull history and correlations |
| Generate a Playbook | Draft repeatable steps from this incident |
| Check Change Events | Look for recent deploys/config changes |
| Search Logs | Query connected observability tools |
| Update Memory | Save learnings after resolve |

**Limits beginners hit:** Only the first **2,000 characters** of `custom_details` / notes are analyzed. Uploads: `.txt` / `.pdf` / `.md` (and images `.jpg` / `.png`), max **100 KB** each, **25** files per conversation. Fact-check every suggestion before you run automation.

### Scribe Agent — deeper how-to

| Step | Action |
| --- | --- |
| 1 | Enable Zoom automated captions (or Teams/Meet path) |
| 2 | Connect Advance to Slack or Teams if you want transcripts visible in chat |
| 3 | AI Settings → enable **Scribe Agent** |
| 4 | Keep auto-launch on for major services, or drive join via Incident Workflow |
| 5 | Put conference URL on the incident; ensure someone joins within 15 minutes |
| 6 | After call: use meeting summary for status updates and PIR drafts |

As of July 23, 2026, Scribe can join bridges **without** a chat surface for internal use (SRE analysis / PIR). You still need Slack/Teams mapping if humans should **see** the transcript in channel.

### Shift Agent — deeper how-to

| Step | Action |
| --- | --- |
| 1 | Enable Advance + Slack |
| 2 | Confirm primary on-call schedules sit on **Level 1** of the escalation policy |
| 3 | (Recommended) Enable Google Calendar Extension |
| 4 | Link PD user ↔ Slack so conflict and coverage notification rules exist |
| 5 | Ask in Advance chat about conflicts; use **Request coverage** when offered |

Coverage candidates get **24 hours** to reply (weekends excluded from that window). After timeout or all declines, you are notified again.

### Insights Agent — deeper how-to

| Prompt type | Example you can paste |
| --- | --- |
| Point in time | How many high urgency incidents were there last week on Payments? |
| Trend | How has the average time to resolve changed over the past 6 complete months for Payments? |
| Period vs period | Was MTTA faster this month than last month for Checkout? |
| Vs baseline | Is aggregate MTTR this month better than the 2025 baseline for Checkout? |

Proactive recommendations go weekly to Account Owner, Admins, and (on Business+) Team Managers — only when there is something useful to suggest for services/teams they own.

### Dynatrace → PagerDuty → agents (brief)

| Layer | What happens | Agent touchpoint |
| --- | --- | --- |
| Detect | Dynatrace Davis Problem | None yet |
| Notify | Dynatrace Problem notification or Workflow “Create incident” → PD Service / Event Orchestration | Clean routing keys and urgency matter for later triage quality |
| Page | PD escalation → human phone/Slack | Shift Agent kept coverage valid |
| Triage | Responder opens incident | **SRE Agent** summarizes Dynatrace link + PD payload + history |
| Collaborate | Zoom/Teams bridge | **Scribe Agent** captures decisions |
| Improve | Week later | **Insights Agent** shows if MTTA/MTTR for that service worsened |

Official SRE Agent sample data sources on the marketing page include AWS, Confluence, Datadog, GitHub, Grafana, CloudWatch. Dynatrace is typically the **ingress** that creates the PD incident (problem notification / webhook / workflow). Enrich SRE Agent with log/runbook connectors you actually use; keep Dynatrace’s problem URL in the PD event so humans and the agent can deep-link.

### AI Actions cost cheat sheet

| Agent / action | AI Actions |
| --- | --- |
| SRE Agent ask or nudge | 4 |
| Scribe (meeting) | About 6 per 30 minutes of bridge + 2 when final summary posts |
| Shift Agent | 0 (included) |
| Insights Agent | 0 (included) |

---

## Data flow map

```
[Dynatrace Problem]
        |
        v
[PD Events / Notification / Workflow]
        |
        v
[PD Incident] ---- optional AIOps Event Orchestration (group/route)
        |
        +----> [Page human via Escalation Policy]
        |              |
        |              +---- Shift Agent (coverage before/during week)
        |
        +----> [SRE Agent] <---- Connectors (logs, runbooks, changes)
        |         | ask / nudges / recommended workflows
        |         v
        |      [Human approves remediation]
        |
        +----> [Incident bridge Zoom/Teams/Meet]
        |         |
        |         v
        |      [Scribe Agent] --> transcript + summary --> channel / PIR
        |
        v
[Resolve incident] --> SRE memory update
        |
        v
[Insights Agent] weekly trends + chat analytics Q&A
```

```
Enable once
  Advance + Slack/Teams
    → toggle 4 agents
    → Level-1 schedules (Shift)
    → Conference URL hygiene (Scribe)
    → Runbook upload + connectors (SRE)
    → Linked user accounts (Insights DMs + Shift notifies)
```

---

## Related files

| File | Purpose |
| --- | --- |
| [8.sh](./8.sh) | Doc and settings navigation reminders (no live API calls) |
| [8-pagerduty-ai-agents-detailed-follow.txt](./8-pagerduty-ai-agents-detailed-follow.txt) | Full chat-ready follow text |
| Adocs twin | `/Users/k/Codes/Pra/P1Githubactions/P1Gactions/app/Adocs/2026-08-25/8-pagerduty-ai-agents-detailed/` |
| Prior POC (API agent, not product suite) | Daily Files `2026-08-25/7-pagerduty-ai-agent-poc/` |

### Official docs (verify anytime)

| Topic | URL |
| --- | --- |
| AI Agents overview | https://www.pagerduty.com/platform/ai-agents/ |
| Fall 2025 launch (names the four) | https://www.pagerduty.com/newsroom/2025-fall-productlaunch/ |
| Advance enablement | https://support.pagerduty.com/main/docs/pagerduty-advance |
| SRE Agent | https://support.pagerduty.com/main/docs/sre-agent |
| Scribe Agent | https://support.pagerduty.com/main/docs/scribe-agent |
| Shift Agent | https://support.pagerduty.com/main/docs/shift-agent |
| Insights Agent | https://support.pagerduty.com/main/docs/insights-agent |
| Dynatrace → PD notifications | https://docs.dynatrace.com/docs/analyze-explore-automate/notifications-and-alerting/problem-notifications/pagerduty-integration |

---

## Commands

UI-first topic. Commands in [8.sh](./8.sh) are bookmarks and checklist one-liners only — **do not** call live PagerDuty APIs unless you explicitly ask later.

```bash
# Open Advance AI Settings in browser (replace subdomain)
open "https://REPLACE_ME.pagerduty.com/ai-settings"
```
