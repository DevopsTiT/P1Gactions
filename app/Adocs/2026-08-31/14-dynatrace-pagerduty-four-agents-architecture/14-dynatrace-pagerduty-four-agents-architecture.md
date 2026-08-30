# Dynatrace PagerDuty Four Agents Architecture

## Decision tree

```
Need an ARB-style architecture capture (like seq 10 Splunk→Dynatrace)?
  What is the project?
    Dynatrace (detect) → PagerDuty (page) → Four Advance AI Agents (assist)
    Agents: SRE · Scribe · Shift · Insights
  What changes technically?
    AS-IS: Dynatrace → PD incident → human does triage/notes/coverage/analytics by hand
    TO-BE: same path + Advance agents beside the human (human still owns blast radius)
    Optional front door: Event Orchestration / alert grouping (noise cut before agents)
  Who / what you need?
    PagerDuty Advance + Admin to enable agents
    Teams and/or Slack; linked users (linkUser)
    Test Service + Level-1 test schedule (never prod)
  Chat surface honesty (Teams-only)?
    SRE / Scribe / Insights Q&A → full POC
    Shift coverage DMs + Insights weekly DMs → Slack-first (use Path B for Shift)
  Cost?
    SRE 4 Actions/ask; Scribe ~6/30min +2 summary; Shift 0; Insights 0
  Related packs?
    PPT twin → seq 13
    Teams-only runbook → seq 6 / 2026-08-25 seq 11
    Noise reduction before agents → seq 7 Event Orchestration
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Project | **Dynatrace → PagerDuty Four AI Agents** architecture design (ARB-style capture) |
| Objective | Design + POC proof that Dynatrace problems become PD incidents, then Advance agents cut toil |
| Why | Detect is solved by Dynatrace; page is solved by PD; triage/notes/coverage/trends still burn humans |
| TO-BE hub | **PagerDuty Advance** agents on top of PD incidents fed by Dynatrace |
| The four | **SRE**, **Scribe**, **Shift**, **Insights** (not four Dynatrace products) |
| Dynatrace role | Ingress that creates/notifies the incident; keep problem URL in the payload |
| Safe demo | Test Service + escalation that pages **only you** |
| Companion PPT | Daily Files `2026-08-31/13-dynatrace-pagerduty-four-agents-ppt/` |

---

## Summary

This note is the **markdown twin** of an ARB-style architecture pack for using **PagerDuty’s four Advance AI agents** on incidents that start in **Dynatrace**. Dynatrace finds the problem. PagerDuty pages the right person. Agents help with triage (SRE), bridge notes (Scribe), on-call coverage (Shift), and analytics (Insights). Humans still confirm remediations and own blast radius. Optional Event Orchestration sits in front to reduce noise so agents are not asked to triage junk. For Teams-only orgs, treat Shift DM coverage and Insights weekly DMs as Slack-first gaps.

---

## Main content

### What this is (beginner)

**Dynatrace** = monitoring / observability SaaS. It opens a **Problem** when something breaks (for example checkout latency).

**PagerDuty** = incident pager. It turns a signal into an **Incident** and notifies on-call.

**PagerDuty Advance** = paid AI layer with an **AI Actions** budget. The four named agents live here.

**The four agents** = purpose-built helpers:

| Agent | Plain English |
| --- | --- |
| SRE Agent | Virtual responder: summarize, use runbook, suggest next steps |
| Scribe Agent | Joins the war-room call; writes transcript + wrap-up |
| Shift Agent | Spots OOO vs on-call conflict; helps get coverage |
| Insights Agent | Answers MTTR/MTTA questions; weekly maturity tips (Slack-first) |

**Not one of the four:** Advance Assistant (chat router), Event Intelligence / grouping, PIR draft helpers. Useful, but not the named suite.

This document is an **architecture design capture** in the same shape as the Splunk→Dynatrace ARB note (summary sheet, AS-IS/TO-BE, data flow, security, open items). It is for POC / design review — fill real Gate/cost/presenter fields when you take it to a formal board.

### Project identity (title block)

| Field | Value for this design |
| --- | --- |
| Title | Architecture Design Proposal for Dynatrace → PagerDuty Four AI Agents |
| Objective | Architecture design + POC enablement (Advance agents on Dynatrace-fed incidents) |
| Gate / approval | *(fill for your org — e.g. design review / POC permit)* |
| Architecture Governance | Standard (platform Ops / SRE tooling) |
| Presenter (Team) | *(fill — e.g. Ops Middleware and Monitoring / SRE)* |
| Line of Business | *(fill)* |
| Design date | 2026/08/31 |
| Engineering PoC | *(fill)* |
| Ops PoC | *(fill)* |
| Platform Architecture PoC | *(fill)* |
| Umbrella product | PagerDuty Advance |
| Detect product | Dynatrace (SaaS) |
| Chat surface | Microsoft Teams and/or Slack; PD web SRE tab |

### Architecture Design Summary Sheet

| Item | Answer |
| --- | --- |
| Objective | Solution design: Dynatrace problems → PD incidents → four Advance agents assist humans |
| Archi Gov. | Standard |
| Background WHY | Dynatrace + PD already detect and page. Humans still dig docs, type bridge notes, chase coverage, and export analytics. Agents cut that toil without removing human control. |
| Architecture Design Overview | Keep Dynatrace as ingress. Land incidents on a PagerDuty Service (optional Event Orchestration for noise). Enable Advance + four agents. Use Teams/Slack for chat; Scribe on meetings; Shift for Level-1 coverage; Insights for trends. Demo only on test Services. |
| Alignment | Complements Dynatrace logging/monitoring roadmap; sits after clean alerting (Event Orchestration optional) |
| API | Not required for product agents UI (custom API agents are a different POC) |
| Cloud / SaaS | Dynatrace SaaS + PagerDuty Advance |
| Project Cost | *(fill — Advance license / AI Actions credits + POC labor)* |
| Production timing | *(fill — after POC pass criteria)* |
| Security Review Status | *(fill — Graph consent for Teams; no PII in channel asks; least privilege scopes)* |
| Architect View | Support adding Advance agents after Dynatrace→PD path is clean; do not expect agents to fix alert storms |
| Companion PPT | `13-Dynatrace-PagerDuty-Four-AI-Agents-ARB-style.pptx` |

### Update and design history

| # | Item | Update detail |
| --- | --- | --- |
| 1 | Architecture capture | ARB-style md created from four-agents + Teams-only + Dynatrace E2E notes (2026-08-31) |
| 2 | Companion PPT | ARB-style 12-slide deck generated (seq 13) |
| 3 | Teams-only honesty | Shift DMs + Insights weekly DMs documented as Slack-first |

| # | Related prior work | Link / folder |
| --- | --- | --- |
| 1 | Four agents detailed | `2026-08-25/8-pagerduty-ai-agents-detailed/` |
| 2 | Four agents POC examples | `2026-08-25/9-pagerduty-four-agents-poc-examples/` |
| 3 | Teams-only permissions | `2026-08-25/10-pagerduty-teams-only-permissions/` |
| 4 | Teams-only ordered POC | `2026-08-25/11-pagerduty-four-agents-teams-only-poc/` |
| 5 | Teams-only architecture expand | `2026-08-31/6-pagerduty-teams-only-architecture/` |
| 6 | Event Orchestration 10 scenarios | `2026-08-31/7-pagerduty-event-orchestration-poc/` |

---

### AS-IS architecture (Solution Context)

**Key messages**

| Message | What it means |
| --- | --- |
| Dynatrace detects | Problem opens when latency/errors/host issues fire |
| PagerDuty pages | Integration / Events API creates an incident; escalation notifies on-call |
| Humans carry the middle | Triage, notes, coverage, and trend reporting are mostly manual |

**AS-IS pic flow**

```
[Dynatrace Problem / Davis]
        |
        v
[PagerDuty Incident]  (+ optional raw noise)
        |
        v
[Escalation → Human on-call]
        |
        +-- dig docs / past tickets by hand
        +-- type bridge notes (or lose them)
        +-- spreadsheet for OOO coverage
        +-- export Analytics CSV for leadership
```

| Node | Role |
| --- | --- |
| Dynatrace | Detect + problem URL |
| PagerDuty Service | Incident object + urgency |
| Escalation / Schedule | Who gets the page |
| Human | All assistive work after the page |

**AS-IS pain**

| Pain | Why you care |
| --- | --- |
| Slow first 10 minutes | Hunting runbooks and similar incidents |
| Lost bridge decisions | No reliable transcript for PIR |
| Coverage gaps | OOO overlaps Level-1 with no assistant |
| Weak weekly learning | Trends need manual Analytics pulls |

---

### TO-BE architecture (Solution Context)

**Key messages**

| Message | What it means |
| --- | --- |
| Same detect → page spine | Dynatrace and PagerDuty stay; agents added beside the human |
| Four agents under Advance | SRE / Scribe / Shift / Insights |
| Human still owns blast radius | Confirm remediations; no silent prod changes |

**TO-BE pic flow**

```
[Dynatrace Problem] --problem URL in payload--> [PagerDuty]
        |
        +-- optional [Event Orchestration / Alert Grouping]  (noise cut)
        |
        v
[Incident on Service] → [Page human]
        |
        +-- [SRE Agent]     triage / runbook / next steps (Teams or PD web)
        +-- [Scribe Agent]  Teams/Zoom/Meet transcript + summary → PIR
        +-- [Shift Agent]   Level-1 OOO conflict → coverage (Slack DM or web Path B)
        +-- [Insights Agent] MTTR/MTTA Q&A in chat; weekly tips Slack-first
        |
        v
[Human confirms] → [Resolve] → SRE memory / later Insights trends
```

| Source / node | Path |
| --- | --- |
| Dynatrace | Problem notification / Workflow / Events → PD Integration Key |
| Event Orchestration (optional) | Route / pause / group before agents see junk |
| Advance | AI Settings → agents Enabled; Teams/Slack Connected |
| Chat | `@pagerduty` / `@PagerDuty advance …` |
| Meeting | Conference URL on incident → Scribe |
| Calendar | Google Calendar Extension for Shift conflicts |

---

### Impacted platforms / surfaces

**Key message:** This design impacts **incident response tooling**, not application business logic.

| Area | Impact | Note |
| --- | --- | --- |
| Dynatrace | Low change | Keep/create PD integration; include problem URL |
| PagerDuty Services / EP / Schedules | Medium | Test Service + Level-1 test schedule for POC |
| PagerDuty Advance | High | Entitlement + agent toggles + AI Actions budget |
| Microsoft Teams / Slack | Medium | Bot install, Graph consent (Teams), linkUser |
| Google Calendar (optional) | Low | Shift conflict detection |
| App code | None for product agents | No app rewrite required for the four agents |

---

### Alignment with monitoring / IR reference path

| Layer | How this design fits |
| --- | --- |
| Detect | Dynatrace (existing or from Splunk→Dynatrace migration) |
| Reduce noise | PD Event Orchestration / Intelligent grouping (seq 7) |
| Page | PagerDuty escalation |
| Assist | Four Advance agents (this design) |
| Improve | Insights + post-incident PIR (Scribe context) |

If Splunk→Dynatrace (P260120F) is your logging migration, this pack is the **next hop**: after logs/problems live in Dynatrace, wire alerting into PD agents.

---

### The four agents (architecture detail)

#### 1) SRE Agent

| Topic | Detail |
| --- | --- |
| What it is | Virtual responder on a PD Service |
| Inputs | Incident context, ~2,000 chars custom_details, runbook files, optional connectors |
| Outputs | Triage summary, past-incident analysis, suggested steps/workflows |
| Surfaces | Teams `@pagerduty` (EA), Incident SRE tab, Ops Console (AIOps+Advance), virtual responder |
| Dynatrace note | Dynatrace **creates** the incident; it is not the main SRE “connector” list item. Enrich with Grafana/Datadog/CloudWatch/Confluence/GitHub as needed |
| Cost | **4 AI Actions** per ask or nudge |
| Memory | Saves on **Resolve** |
| Limits | Runbook ≤100 KB; 25 files/conversation; human confirms remediations |

**Usage case:** Dynatrace “Checkout latency high” on `poc-pd-ai-agents-test` → Teams ask root causes → upload runbook → past incidents → first steps → decline prod remediation → Resolve.

#### 2) Scribe Agent

| Topic | Detail |
| --- | --- |
| What it is | Meeting bot for Zoom / Teams / Google Meet |
| Inputs | Conference URL on incident (passcode in URL if required) |
| Outputs | Live transcript, post-meeting summary, PIR context |
| Surfaces | Auto-join or `@PagerDuty advance scribe` |
| Caps | 1 Scribe per meeting; up to 10 concurrent; human join within **15 minutes** |
| Cost | **~6 / 30 min** + **~2** final summary |
| Safety | Warn attendees; test incident only; keep POC under ~10 minutes |

#### 3) Shift Agent

| Topic | Detail |
| --- | --- |
| What it is | Scheduling assistant for Level-1 conflicts |
| Inputs | Level-1 schedule + Google Calendar OOO |
| Outputs | Conflict visibility; coverage request; schedule override |
| Slack path | DM → Request coverage → accept → override written |
| Teams-only | **Path B:** Calendar + PD web manual override (recommended). Path A: Advance ask in Teams (partial) |
| Cost | **0** AI Actions |
| Safety | Test schedule / test EP only |

#### 4) Insights Agent

| Topic | Detail |
| --- | --- |
| What it is | Conversational analytics + proactive tips |
| Inputs | Team/Service history in PD Analytics |
| Outputs | Counts, MTTR/MTTA trends; weekly maturity tips |
| Teams | On-demand `@pagerduty` Q&A (GA) |
| Slack-first gap | Weekly proactive DMs still documented as Slack |
| Cost | **0** AI Actions |
| Safety | No PII in questions; apply config tips on test Service first |

---

### Data architecture (incident + agent context)

**Key messages**

| Message | What it means |
| --- | --- |
| Incident is the hub object | Agents attach to PD incidents / Services, not to Dynatrace Problems directly |
| Dynatrace problem URL | Put in payload/custom_details for deep-link |
| Chat history (Teams) | Advance needs Graph message-read scopes to use conversation context |
| Service memory | SRE learnings persist after Resolve on that Service |

**Pic flow**

```
[Dynatrace Problem fields]
   → PD event payload (summary, severity, custom_details, problem URL)
   → [PD Incident]
         ├─ Alerts (grouped if EO/grouping on)
         ├─ Chat / Teams channel (Advance reads messages if consented)
         ├─ Conference URL → Scribe transcript store
         ├─ Schedule / override history → Shift
         └─ Analytics aggregates → Insights
```

---

### Security / identity architecture

| Control | What it means | Why you care |
| --- | --- | --- |
| PD roles | Owner/Global Admin enable agents; Responder uses after link | Who can turn agents on vs use them |
| Team Advance access | Per PD team toggle | Limits who can invoke Advance |
| Teams Graph | Admin consent; `ChatMessage.Read(.All)` for Advance | Agents need message context |
| Least privilege | Prefer `User.ReadBasic.All`; avoid `User.Read.All` for POC | Less profile data |
| linkUser | Maps PD user ↔ Teams/Slack user | Actions and personal notifications |
| graphAuth | Delegated user consent when Application scopes missing | Strict tenants |
| Channel visibility | `@pagerduty` replies are visible to members | No customer PII in questions |
| Test blast radius | Test Integration Keys + test EP | Never wake prod rotation |

**Access pic**

```
[Responder]
  → linkUser (Teams/Slack)
  → @pagerduty asks / meeting commands
  → Advance agents (if team has Advance access)

[PD Admin / Owner]
  → AI Settings → enable Advance + agents
  → Authorize Teams/Slack

[MS Admin]
  → Graph Admin consent / appconnect
```

---

### Technical enablement (HLD-style checklist)

| Zone | Components | Path |
| --- | --- | --- |
| Dynatrace | Problem notification / Workflow / Events | → PD Integration Key (test only for POC) |
| PagerDuty core | Service, EP, Schedule, Incident | Test objects: `poc-pd-ai-agents-test`, `poc-shift-agent` |
| Optional EO | Global Event Orchestration | Route/pause/group before page |
| Advance | AI Settings, AI Actions budget | Agents Enabled |
| Teams | PagerDuty app, standard channel, Graph | Channel ↔ Service map |
| Slack (optional) | PD Slack app | Full Shift + Insights weekly DMs |
| Calendar | Google Calendar Extension | Shift conflicts |
| Human UI | Teams chat, PD web SRE tab, Ops Console | Triage / approve |

**Orchestration vs agents (order of concern)**

```
1. Make Dynatrace → PD reliable (correct Service, urgency, problem URL)
2. Cut noise (Event Orchestration / grouping) if storms exist
3. Enable Advance agents
4. Run POC 1→4 on test Service
```

---

### Cost model

| Item | AI Actions |
| --- | --- |
| Enablement (§0) | 0 |
| SRE ask or nudge | 4 |
| Scribe meeting | ~6 per 30 minutes + 2 final summary |
| Shift | 0 |
| Insights | 0 |

---

### Suggested POC afternoon (success criteria)

| Order | Block | Pass if |
| --- | --- | --- |
| 0 | Shared enablement | Advance On; chat Connected; linkUser; test Service pages only you |
| 1 | SRE | Grounded triage in Teams/web; runbook referenced; no unconfirmed remediation |
| 2 | Scribe | Joins meeting; transcript/summary visible |
| 3 | Shift | Path B override + history (or Path A partial); Slack DM deferred if Teams-only |
| 4 | Insights | Number/trend in Teams matches Analytics roughly; weekly DM gap documented |

Time boxes: enablement 30–60 min; each agent 10–20 min; Scribe meeting ≤10 min.

---

### Open items / gaps to fill for a formal board

| Gap | What to fill |
| --- | --- |
| Presenter / PoC names | Real names for your org |
| Gate / cost / timing | Your approval process and Advance commercial quote |
| Security review | Graph consent evidence; data classification for chat logs |
| Prod Dynatrace key | Must stay off POC Services |
| Teams EA for SRE | Confirm tenant has Early Access |
| Slack decision | Full Shift + Insights weekly DMs need Slack or explicit deferral |
| Event Orchestration | Whether noise pack (seq 7) is in scope before agents |
| AI Governance | If your ARB marks AI solutions Mandatory, attach that assessment |

---

## Data flow map

```
AS-IS
  Dynatrace → PagerDuty → Human (manual triage/notes/coverage/analytics)

TO-BE
  Dynatrace Problem (+ problem URL)
    → PD Events / Integration Key
    → [optional Event Orchestration / grouping]
    → Incident → Escalation (test: only you)
         ├─ SRE Agent (Teams/web) — 4 Actions/ask
         ├─ Scribe Agent (meeting) — ~6/30m +2
         ├─ Shift Agent (Slack DM or web+Calendar Path B) — 0
         └─ Insights Agent (Teams Q&A; weekly DM Slack-first) — 0
    → Human confirms → Resolve → SRE memory / later Insights

POST-POC
  Expand Advance team access gradually
  Keep prod Dynatrace keys on hardened Services only
```

---

## Related files

| File | Purpose |
| --- | --- |
| [14.sh](./14.sh) | Open related docs / PPT bookmarks |
| [14-dynatrace-pagerduty-four-agents-architecture-follow.txt](./14-dynatrace-pagerduty-four-agents-architecture-follow.txt) | Chat-ready full capture |
| Style twin (Splunk→Dynatrace ARB md) | `2026-08-31/10-axa-arb-splunk-dynatrace-migration/` |
| Companion PPT | `2026-08-31/13-dynatrace-pagerduty-four-agents-ppt/` |
| Teams-only deep dive | `2026-08-31/6-pagerduty-teams-only-architecture/` |
| Event Orchestration POC | `2026-08-31/7-pagerduty-event-orchestration-poc/` |
| Adocs twin | `/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-31/14-dynatrace-pagerduty-four-agents-architecture/` |

### Official docs

| Topic | URL |
| --- | --- |
| PagerDuty Advance | https://support.pagerduty.com/main/docs/pagerduty-advance |
| SRE Agent | https://support.pagerduty.com/main/docs/sre-agent |
| Scribe Agent | https://support.pagerduty.com/main/docs/scribe-agent |
| Shift Agent | https://support.pagerduty.com/main/docs/shift-agent |
| Insights Agent | https://support.pagerduty.com/main/docs/insights-agent |
| Dynatrace → PagerDuty | https://docs.dynatrace.com/docs/analyze-explore-automate/notifications-and-alerting/problem-notifications/pagerduty-integration |

---

## Commands

UI/docs bookmarks in [14.sh](./14.sh). Do not call live Dynatrace/PagerDuty APIs unless you ask later.

```bash
open "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/13-dynatrace-pagerduty-four-agents-ppt/13-Dynatrace-PagerDuty-Four-AI-Agents-ARB-style.pptx"
open "https://support.pagerduty.com/main/docs/pagerduty-advance"
```
