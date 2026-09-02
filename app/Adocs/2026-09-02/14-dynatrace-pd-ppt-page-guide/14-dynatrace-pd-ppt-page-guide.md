# Dynatrace PagerDuty Four Agents PPT Page Guide

```
How to read this 42-slide deck?
  │
  ├─ Part A (1–14) → Why four agents + story + cost/safety
  ├─ Part B (15–22) → Architecture / ARB-style diagrams
  ├─ Part C (23–42) → Teams-only POC click-path runbook
  └─ Rule everywhere → TEST Service only, never prod pages
```

| Question | Answer |
| --- | --- |
| What is this deck | Combined **Dynatrace → PagerDuty → Four Advance AI Agents** pack |
| Four agents | **SRE**, **Scribe**, **Shift**, **Insights** |
| Prerequisite | **PagerDuty Advance** + Teams/Slack connected |
| Safe demo | Test Service (e.g. `poc-pd-ai-agents-test`) pages **only you** |

## Summary

This guide explains **every slide** in `19-Dynatrace-PagerDuty-Four-Agents-Whole-Pack-NoFooter.pptx`. The deck merges narrative (Part A), design diagrams (Part B), and a hands-on Teams POC runbook (Part C). Dynatrace **detects** problems and **creates** PagerDuty incidents; Advance agents **assist** humans after the page — they do not replace on-call judgment.

---

## Part A — Narrative (Slides 1–14)

### Slide 1 — Cover

**Title:** Dynatrace to PagerDuty · Four AI Agents — Whole Deck

**What it is:** Opening slide for the full 42-page pack. Names the four PagerDuty Advance agents: **SRE**, **Scribe**, **Shift**, **Insights**.

**Three parts previewed:**
- **Part A** — Story, architecture summary, agent detail, cost, safety
- **Part B** — Solution context boxes, impact/alignment/HLD diagrams
- **Part C** — Teams-only POC with click-path steps

**Why it matters:** Sets expectation that this is both a **design review deck** and a **POC runbook**, not a single-purpose doc.

---

### Slide 2 — Whole Pack Agenda

**How to use the deck:**

| Audience / goal | Read order |
| --- | --- |
| Design review or board | Part A → Part B |
| Hands-on Teams POC afternoon | Part C |
| Everyone | Follow **safe demo rule** |

**Safe demo rule:** Use a **test Service** and **Level-1 test schedule**. **Never** route POC to production on-call or real customer pages.

**Format note:** This NoFooter version has **no bottom footer text and no page numbers** (clean slides for projection).

---

### Slide 3 — PART A divider

**Purpose:** Section break introducing **Narrative Architecture**.

**Content source:** Derived from earlier seq 13 material.

**Topics in Part A:** Summary sheet, AS-IS/TO-BE, data flow, per-agent detail, enablement, cost, safety, suggested POC afternoon.

---

### Slide 4 — Architecture Design Summary Sheet

**What it is:** Visual **one-page summary** (diagram-heavy slide; minimal bullet text on slide).

**Typical contents (from pack design):** Boxes for Dynatrace (detect), PagerDuty (incident/page), four agents, human decision point, and optional Event Orchestration.

**How to read it:** Use as a **wall-chart** during review — the “whole story on one slide” before diving into AS-IS/TO-BE.

---

### Slide 5 — Which Agent Do You Need?

**Key message:** Choose the agent by **the job**, not by brand or hype.

**Prerequisite gate (must pass first):**
1. PagerDuty **Advance** enabled
2. **Teams or Slack** connected
3. Agents **enabled** in AI Settings
4. **TEST Service only** for demos

**Critical line:** Without Advance, agent toggles in the UI **do nothing** — you only get normal PagerDuty paging.

**Decision hint:**
- Live triage / RCA → **SRE**
- Meeting notes → **Scribe**
- Coverage / OOO → **Shift**
- MTTR / trends Q&A → **Insights**

---

### Slide 6 — Solution Context AS-IS

**Key message:** Today Dynatrace finds problems and PagerDuty pages people, but **most middle work is still manual**.

**AS-IS flow:**
```
Dynatrace (Davis AI) → creates signal
PagerDuty → incident + escalation → pages on-call
Human → dig docs, type notes, ask about coverage, export CSV for analytics
```

**Pain points:**
- Slow **MTTA** (mean time to acknowledge) and **MTTR** (mean time to resolve)
- Alert **noise**
- **Missed or incomplete** bridge notes
- **Spreadsheet-style** on-call coverage

**Gap stated:** Dynatrace is strong at **detect**. PagerDuty is strong at **page**. Everything between **page and resolve** (triage, notes, coverage, trends) is still human toil.

---

### Slide 7 — Solution Context TO-BE

**Key message:** Same detect→page path, plus **four Advance agents** beside the human. Agents **suggest**; humans **own blast radius**.

**TO-BE flow:**
```
Dynatrace Problem + problem URL in payload
→ PagerDuty Service (+ optional Event Orchestration for noise)
→ Advance Agents (SRE, Scribe, Shift, Insights)
→ Human confirms remediations and resolves
```

**Per-agent role on slide:**
| Agent | Job | Cost model (high level) |
| --- | --- | --- |
| SRE | Triage + runbook + optional connectors | **4 AI Actions** per ask |
| Scribe | Meeting transcript + summary | **~6 per 30 min** + **2** for summary |
| Shift | Coverage / override suggestions | **0 Actions** |
| Insights | MTTR/MTTA Q&A + tips | **0 Actions** |

---

### Slide 8 — End-to-End Data Flow

**Key message:** **Detect → Notify → Page → Assist → Resolve → Learn**

**What the diagram shows:** Linear incident lifecycle with feedback loop:
1. **Detect** — Dynatrace Problem
2. **Notify** — Integration to PagerDuty
3. **Page** — Escalation policy fires
4. **Assist** — One or more Advance agents help in chat/meeting/web
5. **Resolve** — Human closes incident
6. **Learn** — SRE Agent can save **memory** on resolve for similar future incidents

**Why it matters:** Shows agents sit **after** paging, not instead of monitoring or escalation.

---

### Slide 9 — Four Agents at a Glance

**Comparison table slide** for all four agents (capabilities, surfaces, limits).

**Dynatrace-specific tip on slide:**
- Dynatrace usually **creates** the incident (ingress path)
- Dynatrace is **not** typically the main **SRE Agent connector** in the connector list — enrich with Grafana, Datadog, CloudWatch, Confluence, GitHub as needed
- Put **Dynatrace problem URL** in `custom_details` so humans and SRE Agent can deep-link

**Why:** Ensures POC incidents carry enough context for SRE Agent without misconfiguring connectors.

---

### Slide 10 — SRE Agent — Live Triage

**Key message:** SRE reads incident context (~2k chars `custom_details`), runbook, optional connectors, and past incidents. **Human must confirm** any remediation.

**POC story on slide:** Dynatrace “Checkout latency high” on test Service → ask in Teams → upload `poc-checkout-latency.md` runbook → analyze past incidents → first steps → **read** any remediation suggestion → **Resolve** to save memory.

**Limits called out:**
- Runbook **≤ 100 KB**
- **25 files** per conversation
- **No customer PII** in channel questions

**Cost:** **4 AI Actions** per chat ask or nudge.

---

### Slide 11 — Scribe Agent — Bridge Notes

**Key message:** Scribe joins **Zoom / Teams / Google Meet**, streams transcript, posts decisions, actions, attendees.

**Human requirement:** You must **join the meeting within 15 minutes** for reliable auto-join behavior.

**Caps:** **1 Scribe per meeting**; **10 concurrent** Scribe sessions (platform limit).

**Use case:** Incident bridge calls where typing notes in chat is too slow — Scribe becomes the **live note-taker**.

---

### Slide 12 — Shift + Insights (combined slide)

**Shift Agent:** Handles **on-call coverage** questions — who covers when someone is OOO, schedule conflicts, override suggestions. **0 AI Actions** for Shift itself.

**Insights Agent:** **Analytics-style Q&A** — MTTR, MTTA, incident volume over time. **0 AI Actions** for chat Q&A. Weekly proactive tips may be **Slack-first** (Teams gap documented in Part C).

**Why paired:** Both are “ops hygiene” agents, not live firefighting like SRE/Scribe.

---

### Slide 13 — Enablement, Cost, Safety

**Key message:** Turn on **Advance once**, then demo on a **test Service that pages only you**.

**Topics bundled:**
- Admin steps (high level)
- AI Actions budget awareness
- Never attach prod schedules
- Resolve test incidents to avoid polluting analytics/memory

---

### Slide 14 — Suggested POC Afternoon + Open Items

**What it is:** **Agenda-style slide** for a half-day workshop and a parking lot for unresolved design questions.

**Typical afternoon order:** §0 enablement → SRE → Scribe → Shift (alt path) → Insights

**Open items:** Often includes Slack vs Teams gaps, connector choices, Event Orchestration scope, production rollout criteria.

---

## Part B — Design Diagrams (Slides 15–22)

### Slide 15 — PART B divider

Introduces **Design Diagrams** from seq 15: Solution Context, Impacted Platforms, Alignment stack, Technical HLD, Agent hub, checklist.

**Audience:** Architects, platform leads, ARB reviewers.

---

### Slide 16 — Solution Context Diagram AS-IS (expanded)

**Richer AS-IS** than Slide 6 — adds **Apps/Infra**, **Chat (Teams/Slack cards only)**, **Schedule**, **Analytics**.

**Extra pain:** Lost bridge decisions, coverage gaps, manual leadership reporting.

**Chat note:** Pre-agent state = notification **cards only**, no AI in channel yet.

---

### Slide 17 — Solution Context Diagram TO-BE (expanded)

**Adds:** Optional **Event Orchestration** (noise reduction), **Ops HQ** access pattern, explicit **Human decides** box.

**Emphasis:** EO is **optional** but recommended if alert storms exist. Remediations still require **human confirm**.

---

### Slide 18 — Impacted Platforms

**ARB-style legend:**
| Color | Meaning |
| --- | --- |
| Green | Reuse existing |
| Orange | Modify / enable |
| Blue | Primary new design surface |
| Gray | Out of scope |

**Platform notes:**
- **Dynatrace** — reuse detect; keep problem URL; test API key for POC
- **PagerDuty Core** — test Service/EP; schedule hygiene
- **PagerDuty Advance** — enable agents; AI Actions budget; team access
- **Teams/Slack** — bot, `linkUser`, Graph consent
- **Calendar** — optional Google Calendar Extension for Shift
- **Business apps** — **no rewrite** for product agents

---

### Slide 19 — Alignment with Ops / IR Reference Architecture

**Stack layers (top to bottom):**
1. Channel / Users
2. UI / Chat (Teams, Slack, PD web, Ops Console)
3. **Assist (NEW)** — four Advance agents
4. Page / Incident (PD Service, escalation, schedule)
5. Detect (Dynatrace + optional EO)

**Analogy:** D-PRA-style — agents live in **Assist**, not in application API/product layer.

---

### Slide 20 — Technical Infrastructure HLD Overview

**Infrastructure boxes:**
- **Dynatrace** → Problem/Davis → PD integration key + problem URL
- **Optional EO** → routing/grouping
- **PagerDuty** → Service, Incident, Advance Agents, Analytics
- **Teams/Slack chat** → `@pagerduty` asks for SRE/Insights
- **Teams meeting** → Scribe join/transcript
- **PD web** → SRE tab, schedule overrides
- **Admin** → AI Settings, **MS Graph consent**
- **Calendar** → Google extension for Shift

**Footnote:** `graphAuth` only if tenant is Delegated-heavy; prefer **Application** `ChatMessage.Read.All` for Advance.

---

### Slide 21 — Agent Hub Detail

**Concept:** **One incident** from Dynatrace can use **multiple agents** — pick by task.

| Agent | On incident | Cost |
| --- | --- | --- |
| SRE | Summarize, runbook, past incidents, next steps | 4 Actions/ask |
| Scribe | Join meeting, transcript, PIR draft | ~6/30m + 2 |
| Shift | OOO conflict, coverage | 0 Actions |
| Insights | MTTR/MTTA/volume Q&A | 0 Actions |

**Human:** Owns blast radius, approves remediations, **Resolve → SRE memory**.

---

### Slide 22 — Design Checklist Before/During POC

**Checklist categories:**
- **Detect** — Dynatrace → PD **test** key only; problem URL in payload
- **Noise** — EO/grouping if needed
- **Advance** — Teams Connected; agents Enabled
- **Identity** — `linkUser`; `graphAuth` if needed
- **Safe target** — test Service, EP pages only you, test schedule for Shift
- **Per agent** — runbook size, Scribe meeting length, Shift Path B honesty, Insights Slack gap
- **Board pack** — pair PPT with architecture md docs

---

## Part C — Teams-Only POC Runbook (Slides 23–42)

### Slide 23 — PART C divider

Hands-on **Teams-only** click path. Documents honest **Slack-first gaps** for Shift DMs and Insights weekly DMs.

---

### Slide 24 — POC Agenda

**One ordered runbook** for all four agents after shared enablement.

**Order:** §0 → SRE → Scribe → Shift (alternative path) → Insights

---

### Slide 25 — Decision Tree — Which Agent to Prove?

**Branching guide:**

| Need | Agent |
| --- | --- |
| Active triage / RCA / runbook | **SRE** (Teams Early Access) |
| Bridge notes / PIR | **Scribe** |
| OOO / coverage | **Shift** — Path B if Teams-only |
| MTTR / trends | **Insights** |

**Always:** TEST service + Level-1 TEST schedule.

---

### Slide 26 — Shared Gate

**Hard stops:**
- No **PagerDuty Advance** → stop, get trial/sales
- No **PD Admin + MS Admin** → stop (Graph + AI Settings)

**Then run:** 1 SRE → 2 Scribe → 3 Shift → 4 Insights

---

### Slide 27 — Short Takeaway

**Summary slide** (often bullet recap of Part C goals). Reinforces: prove each agent on **test** incidents, document Teams limitations honestly.

---

### Slide 28 — §0 Shared Teams Enablement — Prerequisites

**Do once** before any agent POC. Points to **seq 10** for full Graph scope detail.

**Roles needed:** Teams Admin, MS Admin, PagerDuty Admin.

---

### Slide 29 — §0 Enablement Steps 1–5

| Step | Action |
| --- | --- |
| 1 | Teams Admin allows PagerDuty third-party app |
| 2 | Install PagerDuty app in Teams; add to POC team |
| 3 | Complete PagerDuty **Authorize** flow |
| 4 | MS Admin accepts Graph scopes (`ChatMessage.Read.All`, etc.) |
| 5 | Map channel ↔ **poc-pd-ai-agents-test** Service; EP notifies **only you** |

---

### Slide 30 — §0 Enablement Steps 6–10

| Step | Action |
| --- | --- |
| 6 | PD AI Settings → Teams **Connected** → On |
| 7 | Enable **SRE, Scribe, Insights** (Shift optional for Path A) |
| 8 | Scope Advance to one PD team (optional) |
| 9 | Each user: `@PagerDuty linkUser` (+ `graphAuth` if Delegated-heavy) |
| 10 | Optional Scribe lobby policy for Teams |

---

### Slide 31 — §0 Success Criteria and Safety

**Pass if:** Teams bot responds; channel mapped; agents show Enabled; test incident card appears.

**Safety:** No prod routing keys; no prod schedules; **0 AI Actions** for enablement itself (spend starts at SRE asks / Scribe meetings).

---

### Slide 32 — §1 SRE Agent POC — Goal and Prerequisites

**Goal:** SRE summarizes **TEST** incident in Teams, uses small runbook, suggests next steps.

**Rules:** Human approval before remediation; Teams SRE is **Early Access**.

---

### Slide 33 — §1 SRE Agent Click/Say Steps

**11-step script:** Optional connector → prepare runbook → create test incident → Teams channel → ask root causes → upload runbook → past incidents → first steps → approve/decline remediation → optional web tab → **Resolve**.

**Example asks:**
- `@pagerduty What are some likely root causes?`
- `@pagerduty Analyze past incidents`
- `@pagerduty What steps should I take first?`

---

### Slide 34 — §1 SRE Success, Safety, Cost

**Success:** Sensible summary, runbook cited, no auto-remediation without approval.

**Cost:** **4 AI Actions** per ask/nudge (also via Incident Workflow virtual responder).

---

### Slide 35 — §2 Scribe Agent POC — Teams Meeting Path

**11-step script:** Enable Scribe → optional workflow step → test incident → create Teams meeting → paste URL on incident → wait for auto-join or `@PagerDuty advance scribe` → join within 15 min → speak clearly → end meeting → verify transcript → optional PIR draft → Resolve.

**Keep meeting ≤ ~10 minutes** for POC.

---

### Slide 36 — §2 Scribe Success, Safety, Cost

**Cost:** **~6 AI Actions per 30 minutes** of bridge + **~2** when final summary posts.

**Safety:** Warn attendees recording/transcription; admit from lobby.

---

### Slide 37 — §3 Shift Agent — Honest Teams-Only Status

**Do not claim** full “Request coverage → teammate accepts in Teams DM” — that is **Slack-first**.

| Path | Approach |
| --- | --- |
| **Path A** | Best-effort Teams ask + manual web override — **partial pass** |
| **Path B** | **Recommended** — Google Calendar + PD web schedule override |

---

### Slide 38 — §3 Shift Path B — Recommended Steps

**9 steps:** Document Slack deferral → create `poc-shift-agent` schedule → test EP Level 1 → enable Google Calendar Extension → OOO block overlapping on-call → verify conflict in PD web → create override → verify history → optional Slack re-test later.

---

### Slide 39 — §3 Shift Path A + Success/Safety/Cost

**Path A highlights:** Enable Shift → test schedule → Calendar recommended → ask in Teams about vacation conflict → manual override anyway.

**Cost:** **0 AI Actions** for Shift and manual overrides.

**Safety:** Tell candidate it is POC; Level-1 only; do not claim Teams DM coverage worked.

---

### Slide 40 — §4 Insights Agent — Conversational in Teams

**8-step script:** Enable Insights → pick Team/Service with history → Teams channel → ask volume / MTTR trend / MTTA compare → **verify against PD Analytics UI** → optional rate response → document weekly DM Slack gap.

**Example asks:**
- `@pagerduty How many high urgency incidents were there last week on <Service>?`
- `@pagerduty How has the average time to resolve changed over the past 6 complete months for <Team>?`

---

### Slide 41 — §4 Insights Success + Cost / Surface Cheat Sheet

**Success:** Answers match Analytics UI within reasonable tolerance.

**Cost:** **0 AI Actions** for conversational Q&A in Teams.

**Cheat sheet:** Which questions work in Teams vs which features need PD web or Slack.

---

### Slide 42 — Afternoon Plan + Data Flow + Commands

**Afternoon flow:**
```
§0 Graph + Authorize + linkUser
  → 1 SRE triage in Teams
  → 2 Scribe on Teams meeting
  → 3 Shift Path B (web/Calendar)
  → 4 Insights Q&A in Teams
```

**Copy-paste Teams commands (not shell):**
- `@PagerDuty linkUser`
- `graphAuth` (if Delegated-heavy)
- `@pagerduty What are some likely root causes?`
- `@PagerDuty advance scribe`
- `@pagerduty How has the average time to resolve changed over the past 6 complete months for <Team>?`

**Reminder:** Weekly proactive Insights DMs = **Slack gap** for Teams-only orgs.

---

## Data flow map

```
Dynatrace Problem
      │
PagerDuty Incident (test Service)
      │
┌─────┴─────┬─────────┬─────────┐
SRE      Scribe    Shift   Insights
triage   notes     coverage analytics
      │
Human resolve → SRE memory (optional learn)
```

---

## Related files

| File | Purpose |
| --- | --- |
| `19-Dynatrace-PagerDuty-Four-Agents-Whole-Pack-NoFooter.pptx` | Source deck |
| seq 13 / 15 / 17 | Source parts for A / B / C |
