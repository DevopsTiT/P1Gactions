# Dynatrace PagerDuty Architecture and Four Agents

```
Incident starts where?
  Dynatrace Problem → PagerDuty Incident → human paged
        │
        ├─ Noise storm? → Event Orchestration first (optional)
        │
        └─ After page → pick agent by job
              SRE      → live triage / runbook / next steps
              Scribe   → bridge call notes
              Shift    → OOO vs on-call coverage
              Insights → MTTR/MTTA trends (after or between incidents)
```

| Question | Answer |
| --- | --- |
| What is the spine | **Dynatrace detects** → **PagerDuty pages** → **Advance agents assist** |
| Hub object | **PagerDuty Incident** — agents attach here, not to Dynatrace Problems directly |
| Who decides | **Human on-call** — agents suggest; you approve remediations |
| Prerequisite | **PagerDuty Advance** + Teams/Slack connected + agents enabled |

## Summary

This design keeps **Dynatrace** as the detection source and **PagerDuty** as the paging and incident hub. Four **PagerDuty Advance** agents — **SRE**, **Scribe**, **Shift**, and **Insights** — reduce manual work **after** the page: triage, bridge notes, schedule coverage, and analytics. They do not replace monitoring, escalation, or human judgment. Optional **Event Orchestration** sits in front to cut alert noise before agents and humans see junk.

---

## Architecture — layers and roles

Think of the stack in five layers. Each layer has one job; agents live only in the **Assist** layer.

| Layer | Component | What it does | What it does NOT do |
| --- | --- | --- | --- |
| 1 Detect | Dynatrace (Davis AI) | Opens a **Problem** when latency, errors, or infra issues fire | Page people directly |
| 2 Reduce noise (optional) | PagerDuty Event Orchestration / grouping | Route, pause, group, or suppress noisy alerts | Fix the underlying app |
| 3 Page | PagerDuty Service, Escalation Policy, Schedule | Creates **Incident**, sets urgency, notifies on-call | Triage or write runbooks |
| 4 Assist (NEW) | Four Advance agents | Help triage, notes, coverage, trends | Auto-change prod without approval |
| 5 Improve | Human + SRE memory + Insights | Resolve, learn, track MTTR/MTTA over time | — |

### AS-IS vs TO-BE

**AS-IS:** Dynatrace finds the problem. PagerDuty pages you. You manually hunt runbooks, type bridge notes, chase OOO coverage in spreadsheets, and export Analytics CSV for leadership.

**TO-BE:** Same detect→page spine. After the page, you optionally invoke one or more agents beside you. You still confirm any remediation and own blast radius.

```
AS-IS
  Dynatrace Problem → PD Incident → Human
    (manual triage, notes, coverage, CSV exports)

TO-BE
  Dynatrace Problem (+ problem URL in payload)
    → PD Integration Key
    → [optional Event Orchestration]
    → Incident → Escalation → Human paged
         ├─ SRE Agent     (triage)
         ├─ Scribe Agent  (meeting)
         ├─ Shift Agent   (coverage)
         └─ Insights Agent (analytics)
    → Human confirms → Resolve → SRE memory
```

---

## End-to-end incident lifecycle

### Phase 1 — Detect (Dynatrace)

Dynatrace **Davis AI** correlates signals and opens a **Problem** (for example “Checkout latency high”). At this stage no agent is involved.

**Architecture requirement:** Configure Dynatrace → PagerDuty integration (Problem notification, Workflow, or Events API). Include in the payload:

| Field | Why |
| --- | --- |
| Summary / title | What PD shows on the incident |
| Severity / urgency | Maps to PD urgency |
| **Dynatrace problem URL** | Deep-link for human and SRE Agent |
| `custom_details` (first ~2000 chars) | Context SRE Agent reads |

Dynatrace is the **ingress** — it creates the PD incident. It is **not** typically listed as an SRE Agent “connector” (those are Grafana, Datadog, CloudWatch, Confluence, GitHub, etc.).

### Phase 2 — Notify and optionally reduce noise (PagerDuty)

The PD event lands on a **Service** via Integration Key. If alert storms exist, **Event Orchestration** can route, group, or pause before escalation.

**Why this matters for agents:** If SRE Agent receives 50 duplicate junk incidents, triage quality drops and AI Actions are wasted. Fix noise **before** leaning on agents.

### Phase 3 — Page (PagerDuty core)

Escalation Policy runs. Schedule determines who is Level 1. Human gets phone, SMS, push, or Teams/Slack card.

**Shift Agent** relevance: it helps **before** the next page — spotting OOO overlapping Level-1 on-call — not replacing the pager itself.

### Phase 4 — Assist (four agents)

One incident can use **multiple agents** at different times:

| When | Agent | Typical surface |
| --- | --- | --- |
| First 10 minutes after page | **SRE** | Teams `@pagerduty`, PD web SRE tab, Ops Console |
| Bridge call starts | **Scribe** | Auto-join or `@PagerDuty advance scribe` |
| Before vacation / OOO week | **Shift** | Slack DM (full) or Teams + PD web Path B |
| After resolve or weekly review | **Insights** | Teams `@pagerduty` Q&A |

### Phase 5 — Resolve and learn

Human **Resolves** the incident. **SRE Agent** can save **memory** on that Service (playbook learnings, runbook context). **Insights** uses historical Analytics later for trends.

---

## Data architecture — what flows where

The **PagerDuty Incident** is the hub. Agents do not attach to Dynatrace Problems directly.

```
[Dynatrace Problem fields]
   summary, severity, entity tags, problem URL
        │
        ▼
[PD event payload]
   custom_details (~2k chars used by SRE)
        │
        ▼
[PD Incident]
   ├─ Alerts (grouped if EO on)
   ├─ Teams/Slack channel (Advance reads if Graph consented)
   ├─ Conference URL → Scribe transcript
   ├─ Schedule / override history → Shift
   └─ Analytics aggregates → Insights
```

---

## Security and identity (architecture)

| Control | What it means |
| --- | --- |
| PD Admin / Owner | Enables Advance and agent toggles in AI Settings |
| Team Advance access | Limits which PD teams can invoke agents |
| `linkUser` | Maps PD user ↔ Teams/Slack identity |
| MS Graph consent | `ChatMessage.Read.All` so Advance reads channel context |
| `graphAuth` | Extra delegated consent in strict tenants |
| Test blast radius | Test Integration Keys, test EP pages **only you** |
| No PII in channel asks | `@pagerduty` replies visible to channel members |

---

## The four agents — detailed usage

### 1) SRE Agent — live incident triage

**What it is:** A **virtual responder** tied to a PagerDuty Service. It acts like a junior SRE who reads context fast while you decide.

**When to use:**
- First minutes after a Dynatrace-fed page
- You need “what happened before?” and “what do I try first?”
- You have a runbook but no time to search Confluence

**What it reads:**

| Input | Limit / note |
| --- | --- |
| Incident title, urgency, status | From PD |
| `custom_details` / notes | First **~2000 characters** |
| Uploaded runbooks | `.md` / `.txt` / `.pdf`, **≤100 KB** each, **25 files** max |
| Optional connectors | Grafana, Datadog, CloudWatch, Confluence, GitHub |
| Past incidents on same Service | Correlation and patterns |

**What it outputs:**
- Triage summary
- Likely root causes
- Past / related incident analysis
- Suggested first steps
- Optional remediation workflow — **you must approve**

**Surfaces:**

| Surface | How to start |
| --- | --- |
| Microsoft Teams | `@pagerduty What are some likely root causes?` (Early Access) |
| PD web | Incident → **SRE Agent** tab |
| Ops Console | AIOps + Advance → incident → SRE tab |
| Virtual responder | Incident Workflow or Escalation Policy step |

**Example flow (Dynatrace checkout latency):**
1. Dynatrace opens Problem → PD incident on `poc-pd-ai-agents-test`
2. You get paged; open mapped Teams channel
3. Ask: `@pagerduty What are some likely root causes?`
4. Upload `poc-checkout-latency.md` runbook
5. Ask: `@pagerduty Analyze past incidents`
6. Ask: `@pagerduty What steps should I take first?`
7. If remediation suggested → **read and approve/decline**
8. **Resolve** incident → SRE saves memory for next time

**Cost:** **4 AI Actions** per ask or nudge click.

**Safety:** Never auto-run prod changes. Fact-check connector results. No customer PII in public channel questions.

---

### 2) Scribe Agent — bridge notes and PIR context

**What it is:** A **meeting bot** that joins Zoom, Microsoft Teams, or Google Meet incident bridges.

**When to use:**
- P1/P2 war room where people talk faster than anyone can type
- You need decisions, action items, and attendees captured for PIR

**What it reads:**
- **Conference URL** on the incident (include passcode in URL if required)
- Live audio/captions from the meeting platform

**What it outputs:**
- Live transcript (if chat surface connected)
- Post-meeting summary: decisions, actions, attendees
- Context for later PIR drafts

**Surfaces:**

| Surface | How to start |
| --- | --- |
| Auto-launch | Conference URL on incident; someone joins within **15 minutes** |
| Teams | `@PagerDuty advance scribe` |
| Incident Workflow | “Add Scribe Agent” step |

**Example flow:**
1. Test incident created from Dynatrace signal
2. Create Teams meeting; paste URL on incident
3. Scribe auto-joins (or manual `@PagerDuty advance scribe`)
4. You join within 15 min; speak clearly
5. End meeting (~10 min for POC)
6. Verify transcript and summary in channel or incident
7. Use summary for status update or PIR draft

**Limits:**
- **1 Scribe per meeting**
- **10 concurrent** Scribe sessions (platform cap)
- Human must join within **15 minutes** or auto-join may skip

**Cost:** **~6 AI Actions per 30 minutes** of bridge + **~2** when final summary posts.

**Safety:** Warn attendees about recording/transcription. Admit bot from lobby if policy requires.

---

### 3) Shift Agent — on-call coverage and OOO conflicts

**What it is:** A **scheduling assistant** for Level-1 on-call. It spots when your calendar OOO overlaps primary on-call and helps get coverage.

**When to use:**
- Before vacation or doctor appointment
- Last-minute OOO overlaps Level-1 schedule
- You want override written without spreadsheet ping-pong

**What it reads:**
- **Level-1** schedules on Escalation Policy (only Level 1 by design — less noise)
- **Google Calendar** OOO blocks (via Calendar Extension)

**What it outputs:**
- Conflict detection message
- Coverage request to teammates
- Schedule **override** when someone accepts (Slack path)
- Manual override guidance (Teams Path B)

**Two paths (Teams-only honesty):**

| Path | How it works | Pass criteria |
| --- | --- | --- |
| **Path A (Slack-full)** | Ask in chat → Request coverage → teammate accepts in **Slack DM** → override written | Full automation |
| **Path B (Teams recommended)** | Google Calendar OOO → verify conflict in PD web → **manual override** on schedule | Honest POC pass for Teams-only orgs |

**Example flow (Path B):**
1. Create test schedule `poc-shift-agent` on test EP Level 1
2. Enable Google Calendar Extension
3. Block Friday OOO overlapping your on-call shift
4. Open PD web → see conflict
5. Create override for backup responder
6. Verify override in schedule history

**Cost:** **0 AI Actions** for Shift and manual overrides.

**Safety:** Test schedule and test EP only. Tell coverage candidate it is POC. Do not claim Teams DM coverage worked if you only did Path B.

---

### 4) Insights Agent — analytics Q&A and maturity tips

**What it is:** **Conversational analytics** over PagerDuty Incidents, Services, and Teams — plus optional weekly proactive tips.

**When to use:**
- After incidents: “Are we getting noisier?”
- Before leadership review: MTTR/MTTA trends
- Checking if a service degraded after a change

**What it reads:**
- PD Analytics history for Teams/Services you own
- Incident counts, urgency, resolve/acknowledge times

**What it outputs:**
- Point-in-time counts
- Trend comparisons (6 months, month vs month)
- Weekly maturity tips (Slack DMs — **Slack-first gap** for Teams-only)

**Surfaces:**

| Surface | How to start |
| --- | --- |
| Teams (GA) | `@pagerduty How many high urgency incidents were there last week on <Service>?` |
| Slack | Same pattern in channel |
| Weekly DMs | Account Owner, Admins, Team Managers — **Slack-first** |

**Example asks:**
- `@pagerduty How many high urgency incidents were there last week on Payments?`
- `@pagerduty How has the average time to resolve changed over the past 6 complete months for Checkout?`
- `@pagerduty Was MTTA faster this month than last month for <Team>?`

**Verification:** Always cross-check answers against **PagerDuty Analytics UI** during POC.

**Cost:** **0 AI Actions** for conversational Q&A.

**Safety:** No PII in questions. Apply any suggested platform config on **test Service** first.

---

## How the four agents work together on one incident

Real incidents rarely use only one agent. Typical pattern:

```
T-0   Dynatrace Problem → PD incident → you paged
T+2m  SRE Agent: summarize, runbook, past incidents
T+5m  Bridge starts → Scribe Agent joins meeting
T+30m Human resolves → SRE memory saved
T+1w  Insights Agent: "Did MTTR for this Service worsen?"
```

**Before the incident (Shift):** Shift kept Level-1 coverage valid when primary was OOO — reducing missed pages.

**Not the four agents:** Advance Assistant (chat router), Event Intelligence, Automation Digest, generic PIR draft helpers — useful Advance features, separate from the named suite.

---

## Enablement order (architecture best practice)

```
1. Dynatrace → PD reliable (correct Service, urgency, problem URL)
2. Cut noise (Event Orchestration) if alert storms exist
3. Enable PagerDuty Advance + connect Teams/Slack
4. Toggle agents in AI Settings
5. linkUser for each responder
6. POC on test Service only (§0 → SRE → Scribe → Shift → Insights)
```

---

## Cost model

| Item | AI Actions |
| --- | --- |
| Enablement (§0) | 0 |
| SRE ask or nudge | 4 |
| Scribe meeting | ~6 per 30 min + 2 summary |
| Shift | 0 |
| Insights Q&A | 0 |

---

## Investigation

Source material reviewed:

| Source | Path |
| --- | --- |
| Architecture capture | `2026-08-31/14-dynatrace-pagerduty-four-agents-architecture/` |
| Four agents detailed | `2026-08-25/8-pagerduty-ai-agents-detailed/` |
| Whole PPT (42 slides) | `2026-08-31/19-dynatrace-pd-four-agents-whole-ppt-nofooter/` |
| Page-by-page guide | `2026-09-02/14-dynatrace-pd-ppt-page-guide/` |

---

## Result

Use this mental model: **Dynatrace = eyes**, **PagerDuty = pager + incident record**, **four agents = assistants after the page**. Pick agent by job. Human always owns resolution and prod changes.

---

## Data flow map

```
[Dynatrace Problem + URL]
        │
        ▼
[PD Events / Integration Key]
        │
        ├─ optional [Event Orchestration]
        │
        ▼
[Incident] ──page──► [Human on-call]
        │
        ├─► SRE (4 Actions/ask) ──► approve? ──► resolve ──► memory
        ├─► Scribe (meeting URL) ──► transcript ──► PIR
        ├─► Shift (calendar/schedule) ──► override
        └─► Insights (Analytics) ──► trends / weekly tips
```

---

## Related files

| File | Purpose |
| --- | --- |
| `15-dynatrace-pd-architecture-agents-deep.md` | This document |
| `0-pic.md` | Pic decision tree + flow |
| `3-glossary.md` | Terms |
| Whole PPT | `19-Dynatrace-PagerDuty-Four-Agents-Whole-Pack-NoFooter.pptx` |

## Commands

UI/docs only — see PagerDuty Advance and agent docs in browser. No live API calls in this answer.
