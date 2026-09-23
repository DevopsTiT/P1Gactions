# Four Agents PPT Each Page Explain

```
Need board story?     → Part A (slides 1–14)
Need ARB diagrams?    → Part B (slides 15–22)
Need hands-on POC?    → Part C (slides 23–42)
Safe demo always?     → TEST Service + Level-1 test schedule only
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| File | `warp /Tasks/19-Dynatrace-PagerDuty-Four-Agents-Whole-Pack-NoFooter.pptx` |
| Pages | **42** slides, no footer / no page numbers |
| Spine | Dynatrace detects → PagerDuty pages → four Advance agents assist |
| Four agents | SRE (triage), Scribe (notes), Shift (coverage), Insights (trends) |
| Hard gate | Without **PagerDuty Advance**, agent toggles do nothing |

## Summary

This deck is a **combined pack**: narrative (Part A), design diagrams (Part B), and a Teams-only POC runbook (Part C). Dynatrace finds problems and creates PagerDuty incidents. The four Advance AI agents help **after** the page. Humans still own remediations and blast radius. Use a test Service that pages only you.

## Investigation

Extracted all 42 slides with `python-pptx` from:

`/Users/k/Learnings/AIProject/CursorFiles/warp /Tasks/19-Dynatrace-PagerDuty-Four-Agents-Whole-Pack-NoFooter.pptx`

Same pack also lived under Daily Files `2026-08-31/19-dynatrace-pd-four-agents-whole-ppt-nofooter/`. Prior single-slide explains on 2026-09-23 seq 2–9 cover Summary Sheet, AS-IS, TO-BE, Four Agents at a Glance, and related images.

## Result

Use the page-by-page guide below when presenting or studying. For a design review: A then B. For a POC afternoon: C after Advance + Teams enablement.

---

# Part A — Narrative (Slides 1–14)

## Slide 1 — Cover

**Title on slide:** Dynatrace to PagerDuty · Four AI Agents — Whole Deck

**What it is:** Opening cover. Lists the four agents: **SRE | Scribe | Shift | Insights**.

**Three parts previewed:**

| Part | What you get |
| --- | --- |
| A Narrative | Architecture summary, AS-IS/TO-BE story, agent detail, cost/safety |
| B Design diagrams | Solution context, Impact, Alignment, HLD, agent hub, checklist |
| C Teams-only POC | §0 enablement then SRE → Scribe → Shift → Insights click path |

**Why it matters:** Sets expectation this is both a **board/design** deck and a **hands-on runbook**, not one or the other.

---

## Slide 2 — Whole Pack Agenda

**Table on slide:**

| Part | Source | What you get | Slides (approx) |
| --- | --- | --- | --- |
| A | seq 13 narrative PPT | Summary sheet, AS-IS/TO-BE, agents, enablement | ~11 |
| B | seq 15 design diagrams | Visual Solution Context, Impact, Alignment, HLD, hub | ~7 |
| C | seq 17 Teams-only POC | Full §0–§4 click path for Teams-only orgs | ~19 |

**How to use:**

| Goal | Read order |
| --- | --- |
| Design review / board | Part A → Part B |
| Hands-on Teams POC afternoon | Part C |
| Everyone | Safe demo rule |

**Safe demo rule:** Test Service + Level-1 test schedule. Never prod pages.

**Format note:** No footer text and no page numbers on any slide (clean projection).

---

## Slide 3 — PART A Divider

**Purpose:** Section break for Narrative Architecture.

**Says:** Content comes from earlier seq 13 (Dynatrace → PagerDuty Four AI Agents). Topics: Summary sheet, AS-IS/TO-BE, data flow, agent detail, enablement, cost, safety, POC afternoon.

**Beginner tip:** Treat this like a chapter title page — no decisions yet.

---

## Slide 4 — Architecture Design Summary Sheet

**What it is:** One-page ARB-style summary table (the “elevator pitch”).

| Item | Answer (plain English) |
| --- | --- |
| Objective | Prove Dynatrace Problems become clean PD incidents, then four agents help humans |
| Background WHY | DT finds the problem; humans still dig docs, take notes, fix coverage, report trends. Agents cut that **toil** |
| Design Overview | DT Problem → PD Service (optional Event Orchestration) → page on-call → SRE / Scribe / Shift / Insights |
| Not one of the four | Advance Assistant (router), Event Intelligence, PIR drafts — related, not the named suite |
| Cloud / SaaS | Dynatrace SaaS + PagerDuty Advance |
| Chat | Teams and/or Slack. Teams-only: SRE/Scribe/Insights Q&A strong; Shift DMs Slack-first |
| Cost model | SRE 4 Actions/ask; Scribe ~6/30min +2 summary; Shift 0; Insights 0 |
| Safety | Test Service / test schedule only; human confirms remediations |

**Toil** = repetitive work that does not need a senior brain every time.

---

## Slide 5 — Which Agent Do You Need?

**Key message:** Pick the agent from the **job**, not from the logo.

| Job | Agent | When |
| --- | --- | --- |
| Active triage / RCA / runbook | SRE Agent | First ~10 minutes after Dynatrace pages |
| Bridge notes / PIR draft | Scribe Agent | War room Zoom/Teams/Meet |
| OOO vs on-call / coverage override | Shift Agent | Before the next page; Level-1 schedules |
| MTTR / MTTA / volume trends | Insights Agent | After incidents; leadership prep |

**Prerequisite gate (must pass first):**

```
PagerDuty Advance enabled
  → connect Teams/Slack
  → enable agents in AI Settings
  → TEST service only
```

**Critical line:** Without Advance, agent toggles **do nothing** — you only get normal paging.

---

## Slide 6 — Solution Context AS-IS

**Key message:** Dynatrace detects and creates/notifies a PD incident. Humans still do triage, notes, coverage, and analytics mostly by hand.

```
Dynatrace (Problem / Davis AI)
  → creates signal
PagerDuty (Incident + escalation)
  → pages on-call
Human on-call
  → dig docs, type notes, ask coverage, export CSV
Pain
  → slow MTTA/MTTR, noise, missed notes, spreadsheet coverage
```

**AS-IS gap:** Dynatrace is strong at **detect**. PagerDuty is strong at **page**. The middle toil (triage, bridge notes, coverage, trends) is still mostly human.

| Term | What it means |
| --- | --- |
| MTTA | Mean time to acknowledge (how fast someone says “I am looking”) |
| MTTR | Mean time to resolve (how fast the incident closes well) |

---

## Slide 7 — Solution Context TO-BE

**Key message:** Same Dynatrace → PagerDuty path, plus four Advance agents beside the human. Agents **suggest**; humans still **own blast radius**.

```
Dynatrace (Problem URL in PD payload)
  → PagerDuty Service (+ optional Event Orchestration)
  → Advance Agents (SRE · Scribe · Shift · Insights)
  → Human decides (confirm remediation, own the page)
```

| Agent | Job on TO-BE | Cost |
| --- | --- | --- |
| SRE | Triage + runbook | 4 Actions / ask |
| Scribe | Meeting transcript | ~6/30m + 2 summary |
| Shift | Coverage / override | 0 Actions |
| Insights | MTTR Q&A + tips | 0 Actions |

---

## Slide 8 — End-to-End Data Flow

**Key message:** Detect → Notify → Page → Assist → Resolve → Learn

| Stage | System | Agent touchpoint |
| --- | --- | --- |
| 1 Detect | Dynatrace Davis Problem | None yet — keep problem URL in the event |
| 2 Notify | Dynatrace → PD Events / Workflow | Clean routing key + urgency matter |
| 3 Optional noise cut | PD Event Orchestration / grouping | Fewer junk incidents before agents run |
| 4 Page | Escalation Policy | Shift kept coverage valid beforehand |
| 5 Triage | Teams/Slack/PD web | SRE Agent summarizes + runbook + next steps |
| 6 Collaborate | Zoom / Teams / Meet bridge | Scribe joins, transcript, summary, PIR context |
| 7 Resolve | PD Resolve | SRE service memory updates |
| 8 Improve | Analytics / chat next week | Insights MTTR/MTTA Q&A (weekly DMs Slack-first) |

**Why it matters:** Agents sit **after** paging, not instead of monitoring or escalation.

---

## Slide 9 — Four Agents at a Glance

| Agent | What it is | Primary surface | AI Actions | Teams-only |
| --- | --- | --- | --- | --- |
| SRE | Virtual responder: context, runbook, next steps | Teams `@pagerduty` / PD SRE tab | 4 / ask | Full (EA) |
| Scribe | Joins meeting; transcript + wrap-up | Teams meeting + advance scribe | ~6/30m +2 | Strong |
| Shift | OOO conflict + coverage override | Slack DMs / web+Calendar Path B | 0 | Partial |
| Insights | Analytics Q&A + weekly maturity tips | Teams `@pagerduty` Q&A | 0 | Q&A yes; weekly DM Slack |

**Dynatrace tip (footer of slide):**

| Tip | Meaning |
| --- | --- |
| DT usually **creates** the incident | Dynatrace is **ingress** |
| DT is not the main SRE connector list item | Enrich with Grafana / Datadog / CloudWatch / Confluence / GitHub |
| Keep Problem URL in `custom_details` | Humans + SRE Agent can deep-link |

---

## Slide 10 — SRE Agent — Live Triage

**Key message:** Reads incident + ~2k chars `custom_details` + runbook + optional connectors. Suggests next steps; human must confirm remediations. Memory saves on Resolve.

| Surface | How to start | Good first ask |
| --- | --- | --- |
| MS Teams (Early Access) | `@pagerduty …` in mapped channel | What are some likely root causes? |
| Incident SRE tab | PD web → incident → SRE Agent | Analyze past incidents |
| Ops Console | AIOps + Advance → SRE tab | What steps should I take first? |
| Virtual responder | Incident Workflow / Escalation (EA) | Same 4 Actions per trigger |

**POC story:** Dynatrace “Checkout latency high” on test Service → Teams ask → upload `poc-checkout-latency.md` → past incidents → first steps → READ any remediation → Resolve.

**Limits:** Runbook ≤100 KB; 25 files/conversation; no customer PII in channel questions.

---

## Slide 11 — Scribe Agent — Bridge Notes

**Key message:** Joins Zoom / Teams / Meet; streams transcript; posts decisions / actions / attendees. Human must join within **15 minutes** for auto-join. Cap: **1 Scribe/meeting**; **10 concurrent**.

| Step | Action |
| --- | --- |
| 1 | Enable Scribe in AI Settings (US often manual; EU may default on) |
| 2 | Put Teams/Zoom/Meet URL (with passcode) on the test incident |
| 3 | Auto-join OR Teams: `@PagerDuty advance scribe` |
| 4 | Join yourself within 15 minutes; admit lobby if needed |
| 5 | Speak symptom / cause / decision clearly |
| 6 | End meeting → confirm summary → optional PIR draft |

**PIR** = Post-Incident Review (write-up after the fire).

---

## Slide 12 — Shift + Insights (combined)

### Shift Agent

| Topic | Detail |
| --- | --- |
| Job | Detect OOO vs Level-1 on-call; request coverage; write override |
| Cost | 0 AI Actions |
| Slack path | Conflict DM → Request coverage → accept → schedule update |
| Teams-only | Path B recommended: Google Calendar + PD web manual override |
| Safety | Test schedule / test EP only — never prod primary |

### Insights Agent

| Topic | Detail |
| --- | --- |
| Job | Conversational MTTR/MTTA/volume; weekly maturity tips |
| Cost | 0 AI Actions |
| Teams | On-demand `@pagerduty` Q&A is available; sanity-check vs Analytics UI |
| Slack-first gap | Weekly proactive recommendation DMs still documented as Slack |

---

## Slide 13 — Enablement, Cost, Safety

**Key message:** Enable Advance once. Demo on a test Service that pages only you.

| Layer | Do this |
| --- | --- |
| 0 Shared | Advance On · Teams/Slack Connected · linkUser · test Service map |
| Graph (Teams) | ChatMessage.Read(.All) for Advance; prefer User.ReadBasic.All |
| Dynatrace | Test integration / routing key only; problem URL in payload |
| SRE connectors | Optional one real connector (not Dynatrace as “connector list” item) |
| Cost | SRE 4/ask · Scribe ~6/30m+2 · Shift 0 · Insights 0 |
| Safety | No prod escalation · confirm remediations · no PII in channel asks |

---

## Slide 14 — Suggested POC Afternoon + Open Items

| Order | Block | Time box |
| --- | --- | --- |
| 0 | Shared enablement (Admins) | 30–60 min |
| 1 | SRE Agent on Dynatrace-shaped test incident | 15–20 min |
| 2 | Scribe short Teams meeting (≤10 min) | 15–20 min |
| 3 | Shift Path B (Calendar + web override) | 10–15 min |
| 4 | Insights conversational Q&A | 10–15 min |

| Open item | Note |
| --- | --- |
| Advance entitlement | Need trial/add-on before toggles work |
| Teams Early Access for SRE | Confirm tenant has Teams EA |
| Shift full DM path | Needs Slack — document if Teams-only |
| Insights weekly DMs | Slack-first — document gap |
| Prod keys | Never point Dynatrace prod at POC Services |

---

# Part B — Design Diagrams (Slides 15–22)

## Slide 15 — PART B Divider

**Purpose:** Section break for Design Diagrams (from seq 15). Topics: AS-IS/TO-BE hub diagrams, Impacted Platforms, Alignment stack, Technical HLD, Agent hub, checklist.

**Audience:** Architects, platform leads, ARB reviewers.

---

## Slide 16 — Solution Context Diagram AS-IS (expanded)

Richer AS-IS than Slide 6. Adds Apps/Infra, Chat, Schedule, Analytics.

```
Apps / Infra (Checkout · hosts · DB) ──monitored──► Dynatrace Davis Problem
                                                      │
                                                      ▼
                                                 PagerDuty Incident + Escalation
                                                      │
                            ┌─────────────────────────┼─────────────────────────┐
                            ▼                         ▼                         ▼
                     Human: Ack, dig docs      Schedule: Level-1         Analytics: manual CSV
                     type notes, ask coverage  Manual OOO overrides      for leadership
                            │
                     Chat: Teams/Slack cards only (no AI agents yet)
```

**Pain:** Slow first 10 min; lost bridge decisions; coverage gaps; manual trends.

**Gap line:** Detect and Page exist. The **assist** layer between page and resolve is human-only.

---

## Slide 17 — Solution Context Diagram TO-BE (expanded)

```
Dynatrace (Problem + problem URL in PD payload)
  → Optional EO (route / pause / group — noise reduction)
  → PagerDuty Incident hub + Advance AI Agents
       SRE · Scribe · Shift · Insights
  → Ops HQ (Teams / PD web)
  → Human decides (confirm remediations · own blast radius · Resolve → SRE memory)
```

**Emphasis:** Event Orchestration is **optional** but useful for alert storms. Remediations still need **human confirm**.

---

## Slide 18 — Impacted Platforms

**ARB-style legend:**

| Color | Meaning |
| --- | --- |
| Green | Reuse existing (Dynatrace / PD / chat) |
| Orange | Modify / enable (Advance + agents) |
| Blue | Primary design surface |
| Gray | Out of scope (app business logic) |

| Platform | Impact |
| --- | --- |
| Dynatrace | Reuse detect ingress; keep problem URL; test key for POC |
| PagerDuty Core | Modify — test Service/EP; Level-1 test schedule; key hygiene |
| PagerDuty Advance | Primary — enable agents; AI Actions budget; Team Advance access |
| Teams / Slack | Modify — bot + linkUser; Graph consent (Teams); channel map |
| IT / IT Platform | Highlighted impact — IR tooling change |
| Cloud / SaaS Ops | Monitoring-Alerting layer (Dynatrace + PD SaaS) |
| Calendar (optional) | Google Calendar Ext. for Shift conflicts |
| Business Apps | No code rewrite for product agents |

---

## Slide 19 — Alignment with Ops / IR Reference Architecture

**Key message:** Dynatrace (detect) + PagerDuty Advance agents (assist) on the incident response path.

**Reference stack (top → bottom):**

```
Channel / Users     On-call · Commander · Leadership
UI / Chat           Microsoft Teams · Slack · PD web · Ops Console
Assist (NEW)        SRE · Scribe · Shift · Insights  (PagerDuty Advance)
Page / Incident     PD Service · Escalation · Schedule · Incident
Detect              Dynatrace Problems · optional Event Orchestration
```

**D-PRA analogy:** Partner/SaaS + Ops Monitoring-Alerting layer — agents sit in **Assist**, not in app API product layer.

---

## Slide 20 — Technical Infrastructure HLD Overview

**Key message:** Dynatrace sends problems to PagerDuty; Advance agents attach to the incident and chat/meeting surfaces. Teams path needs Graph message-read for Advance; Shift full DMs prefer Slack.

```
Apps / Infra ──► Dynatrace (Problem/Davis, Notify → PD key, problem URL)
                      │
                      ▼
              Optional EO (Event Orchestration / Alert Grouping)
                      │
                      ▼
              PagerDuty (Service · Incident · Advance Agents · Analytics)
                 │              │                │
                 ▼              ▼                ▼
        Teams/Slack chat   Teams meeting     PD web
        @pagerduty asks    Scribe join       SRE tab / schedule override
        SRE · Insights     transcript
                 ▲
   Responder: linkUser · graphAuth*
   Admin: PD AI Settings · MS Graph consent
   Calendar: Google Calendar Ext. (Shift)
```

**Footnote:** `graphAuth` only if tenant is Delegated-heavy. Prefer Application `ChatMessage.Read.All` for Advance.

---

## Slide 21 — Agent Hub Detail — Four Agents on One Incident

**Key message:** One Dynatrace-fed incident can use **multiple** agents; pick by job.

```
PD Incident (from Dynatrace Problem + custom_details / problem URL)
   ├── SRE: summarize · runbook · past incidents · next steps (4 Actions/ask)
   ├── Scribe: join meeting · transcript · wrap-up → PIR (~6/30m + 2)
   ├── Shift: Level-1 OOO · Slack DM OR Path B Calendar+web (0 Actions)
   ├── Insights: MTTR/MTTA/volume Q&A · weekly tips Slack-first (0 Actions)
   └── Human: owns blast radius · approve remediations · Resolve → SRE memory
```

---

## Slide 22 — Design Checklist — Before / During POC

| Area | Checklist item |
| --- | --- |
| Detect | Dynatrace → PD **test** Integration Key only; problem URL in payload |
| Noise (optional) | Event Orchestration / grouping if alert storms exist |
| Advance | AI Settings → Teams/Slack Connected → agents Enabled |
| Identity | Each POC user: linkUser; graphAuth if Delegated-heavy |
| Safe target | `poc-pd-ai-agents-test`; EP pages only you; `poc-shift-agent` Level-1 |
| SRE | Runbook ≤100 KB; confirm remediations; Resolve to save memory |
| Scribe | Meeting ≤10 min POC; warn attendees; lobby admit |
| Shift | Teams-only → Path B web+Calendar; do not claim Slack DM worked |
| Insights | Ask in Teams; document weekly DM Slack gap |
| Board pack | Pair this PPT with architecture md + narrative PPT |

---

# Part C — Teams-Only POC Runbook (Slides 23–42)

## Slide 23 — PART C Divider

Hands-on Teams-only click path (from seq 17). Order: §0 shared enablement, then SRE → Scribe → Shift → Insights. Honest Slack-first gaps documented for Shift DMs and Insights weekly DMs.

---

## Slide 24 — Agenda (POC)

**Key message:** One ordered Teams-only runbook for all four named Advance agents. Shared enablement once, then prove 1→2→3→4.

| # | Section | Focus |
| --- | --- | --- |
| 1 | Decision tree + gate | Which agent; Advance + Admins required |
| 2 | §0 Shared enablement | Teams app, Graph, Advance, linkUser |
| 3 | §1 SRE Agent | Triage / runbook / next steps in Teams |
| 4 | §2 Scribe Agent | Teams meeting transcript + summary |
| 5 | §3 Shift Agent | Honest gap; Path A / Path B |
| 6 | §4 Insights Agent | MTTR Q&A in Teams; weekly DM gap |
| 7 | Cheat sheet + schedule | Cost, surfaces, afternoon plan |

---

## Slide 25 — Decision Tree — Which Agent to Prove?

```
Active triage / RCA / runbook?  → 1) SRE Agent (Teams Early Access)
Bridge notes / PIR draft?       → 2) Scribe Agent (Teams meeting + chat)
On-call OOO / coverage?         → 3) Shift Agent
  Full Slack DMs needed? YES    → Path B (web + Calendar) for Teams-only
  Best-effort                   → Path A (Advance ask)
Ops health / MTTR / trends?     → 4) Insights Agent (Teams chat)
  Weekly proactive maturity DMs → Slack-only today → document gap

ALWAYS: TEST service + Level-1 TEST schedule — never prod pages
```

---

## Slide 26 — Shared Gate — Do Once Before Any POC

```
Have PagerDuty Advance?
  NO  → Sales / trial first
  YES → continue

PD Admin + MS Admin?
  NO  → stop; need both (Graph + AI Settings)
  YES → §0 Shared enablement

Then run in order: 1 SRE → 2 Scribe → 3 Shift (alt) → 4 Insights
```

**Safe demo rule:** Dedicated test Service (example: `poc-pd-ai-agents-test`). Escalation on that service must notify **only you**. Never attach a production primary schedule for Shift POC.

---

## Slide 27 — Short Takeaway

| Key point | Detail |
| --- | --- |
| What this deck is | Ordered Teams-only runbook for all four named AI agents |
| Builds on | Earlier agents POC + Teams permissions work |
| Full Teams POC | SRE, Scribe, Insights conversational chat |
| Partial / alternate | Shift — Slack-first; use Path B or Path A |
| Insights weekly DMs | Still Slack-first; Teams covers on-demand Q&A only |
| Who spends AI Actions | SRE and Scribe consume; Shift and Insights usually 0 |
| Safe demo rule | Test Service + escalation that pages only you |

---

## Slide 28 — §0 Shared Teams Enablement — Prerequisites

**Do this once.** Reuse for all four POCs.

| Need | What it means | Why you care |
| --- | --- | --- |
| PagerDuty Advance | Paid AI platform + AI Actions budget | Without it, agent toggles do nothing |
| PD Admin / Owner | Can open AI Settings and authorize Teams | Turns agents and chat on |
| Microsoft / Teams Admin | Consent Graph; allow third-party apps | Bot cannot read chats or create meetings |
| One standard Teams channel | Not private or shared | PD app does not support private/shared |
| Test Service | e.g. `poc-pd-ai-agents-test` | Fake incidents stay off prod rotations |
| Linked users | Each POC person runs linkUser | Actions and auto-add need identity map |

---

## Slide 29 — §0 Enablement Steps (1–5)

| Step | Action |
| --- | --- |
| 1 | Teams Admin: allow PagerDuty (or PagerDuty EU) third-party app |
| 2 | Install PagerDuty in Teams → Add to team → pick one POC team |
| 3 | Complete the PagerDuty Authorize flow for that team connection |
| 4 | MS Admin accepts Graph scopes. Prefer `ChatMessage.Read.All` and `User.ReadBasic.All` |
| 5 | Map channel ↔ Service `poc-pd-ai-agents-test`. Escalation must notify only you |

---

## Slide 30 — §0 Enablement Steps (6–10)

| Step | Action |
| --- | --- |
| 6 | PD web → AI → AI Settings → Chat Integrations → Teams Connected → On |
| 7 | Enable SRE, Scribe, Insights. Enable Shift only if you want Path A |
| 8 | Optional: limit Advance access to one PD team that owns the test Service |
| 9 | Each POC user: `@PagerDuty linkUser`. If Delegated-heavy, also `graphAuth` |
| 10 | Optional Scribe lobby: MS Admin may set Application Access Policy (US AppId `05ffe668-…` or EU `8f79a561-…`) |

---

## Slide 31 — §0 Success Criteria and Safety

| Check | Pass if |
| --- | --- |
| App present | PagerDuty bot responds in the POC team |
| Graph OK | No UPDATE AVAILABLE blocking Advance features |
| Advance Teams On | AI Settings shows Teams Connected / Enabled |
| Agents On | SRE, Scribe, Insights show Enabled |
| Identity | Your PD user is linked (linkUser done) |
| Safe target | Test Service maps to POC channel; only you get pages |

| Safety rule | Why |
| --- | --- |
| One team, one channel, one test Service | Limits blast radius and Graph surface |
| Standard channel only | Private/shared channels unsupported |
| No prod escalation | Prevents waking the real rotation |
| Prefer User.ReadBasic.All | Least privilege for POC |

**AI Actions for §0:** 0 for enablement itself. Spend starts when you ask SRE or run Scribe.

---

## Slide 32 — §1 SRE Agent POC — Goal and Prerequisites

**Goal:** Prove SRE Agent triages a Dynatrace-shaped **test** incident in Teams (or PD web tab).

| Need | Detail |
| --- | --- |
| Advance + Teams Connected | From §0 |
| Agents Enabled | SRE Enabled (Teams often Early Access) |
| Test Service | `poc-pd-ai-agents-test` mapped to the POC channel |
| Runbook file | One `.md` or `.txt` under 100 KB |
| Optional connectors | Grafana, Datadog, New Relic, CloudWatch, Confluence, GitHub |
| Optional UI | Incident SRE Agent tab in PD web; Ops Console needs AIOps + Advance |

---

## Slide 33 — §1 SRE Agent — Click / Say Steps

1. Optional: AI Settings → SRE Agent → add ONE connector you use (Dynatrace creates incidents; usually not the main SRE connector list).
2. Prepare runbook `poc-checkout-latency.md` with 5–10 clear steps.
3. Create a low-risk test incident on `poc-pd-ai-agents-test` (UI Create incident). No prod routing key.
4. Open the mapped Teams channel. Confirm the incident card appears.
5. Type: `@pagerduty What are some likely root causes?`
6. Upload / update runbook when offered (or use PD web Incident → SRE Agent tab).
7. Ask: `@pagerduty Analyze past incidents`
8. Ask: `@pagerduty What steps should I take first?`
9. If remediation suggested: read it, then approve or decline. Do not auto-run against prod.
10. Optional: PD web / Ops Console SRE Agent tab.
11. Resolve the test incident so service memory can save learnings.

---

## Slide 34 — §1 SRE Agent — Success, Safety, Cost

| Check | Pass if |
| --- | --- |
| Triage reply | Agent posts a grounded summary in Teams (or web tab) |
| Runbook | A later answer references your uploaded steps |
| Human control | No remediation ran without an explicit confirm |
| Memory | After resolve, a later ask on the same service feels more specific |

| Safety rule | Why |
| --- | --- |
| Test Service only | Avoids waking the real rotation |
| Confirm before remediations | Agent suggests; humans own blast radius |
| Fact-check log/change claims | AI can be wrong; verify in monitoring / deploy tools |
| Cap custom details noise | Only first ~2,000 characters of custom details are analyzed |
| No customer PII in the question | Teams channel members can see replies |

**AI Actions:** 4 per chat ask or nudge click (also via Incident Workflow / Escalation virtual responder).

---

## Slide 35 — §2 Scribe Agent POC — Teams Meeting Path

**Key message:** Prove Scribe joins a short Teams meeting on a test incident, streams transcript, posts wrap-up. Keep POC meeting under ~10 minutes. Human must join within 15 minutes for auto-join.

1. Confirm Scribe Agent Enabled (US often needs manual toggle; EU may default on).
2. Optional: Incident Workflow step Add Scribe Agent on the test Service.
3. Create test incident on `poc-pd-ai-agents-test`.
4. Create/open a short Teams meeting. Copy join URL (include passcode if required).
5. Paste conference URL onto the incident conference / meeting field in PagerDuty.
6. Open linked Teams incident channel or chat.
7. Wait for auto-join OR type: `@PagerDuty advance scribe` → Add Scribe Agent to meeting → confirm URL.
8. Join yourself within 15 minutes. Admit Scribe if in lobby.
9. Speak 2–3 clear sentences: symptom, suspected cause, decision.
10. End meeting. Confirm transcript activity and post-meeting summary.
11. Optional: ask Advance for Post-Incident Review draft. Resolve test incident.

---

## Slide 36 — §2 Scribe Agent — Success, Safety, Cost

| Check | Pass if |
| --- | --- |
| Join | Scribe appears in the Teams meeting (or joins per product rules) |
| Transcript | Teams chat or internal capture shows spoken content |
| Summary | Wrap-up lists decisions, actions, attendees |
| PIR helper | Later PIR / status draft can reuse bridge context |

| Safety rule | Why |
| --- | --- |
| Test incident + short meeting | Avoids recording a real customer bridge by accident |
| Warn attendees | People should know the call is transcribed |
| One Scribe per meeting | Product limit; do not double-add |
| Cap concurrent meetings | Up to 10 concurrent Scribe meetings account-wide |
| Keep POC under ~10 minutes | Limits AI Actions spend |

**AI Actions:** ~6 per 30 minutes of bridge + ~2 when the final summary posts.

---

## Slide 37 — §3 Shift Agent — Honest Teams-Only Status

**Key message:** Do **not** claim full Request coverage → teammate accepts in Teams DM. That path is Slack-first.

| Fact | What it means |
| --- | --- |
| Slack-first product | Docs/pricing describe Shift with Slack; conflict and coverage notifications wire to Slack |
| Teams-only gap | Full coverage accept automation in Teams DMs is not expected |
| Still give a step path | Use Path A (best-effort) or Path B (recommended: web + Calendar) |

| Path | Approach |
| --- | --- |
| Path A — best-effort | Ask Advance in Teams about OOO conflict. Manual override in PD web. Mark result: partial pass. |
| Path B — recommended | Document Slack DM POC deferred. Google Calendar Extension + OOO block. PD web schedule override + history. |

---

## Slide 38 — §3 Shift Path B — Recommended Steps (Teams-Only)

**Key message:** Prove OOO vs on-call conflict handling with Calendar + web override. Defer full Slack DMs.

1. Document: Full Shift Agent Slack DM POC deferred — Teams-only org.
2. Create test schedule `poc-shift-agent` with you primary on a known near-term window.
3. Attach it to Level 1 of a test escalation policy (not prod).
4. Admin enables Google Calendar Extension; you authorize calendar.
5. Create an OOO block that overlaps the on-call window.
6. In PagerDuty web, open the schedule and confirm conflict / overlap is visible.
7. Create a schedule override for the coverage person for that window.
8. Confirm the override appears in schedule history.
9. Optional later: when Slack exists, re-run full Request coverage → accept DM POC.

---

## Slide 39 — §3 Shift Path A + Success / Safety / Cost

**Path A highlights:** Enable Shift toggle; Level-1 test schedule; Calendar Extension recommended. Block OOO overlapping your window. Ask in Teams: `I am on vacation <date>. Do I have a conflict?` If Request coverage appears, teammate accept may still need Slack. Always close with a manual schedule override in PD web.

| Path | Pass if |
| --- | --- |
| Path A | Conflict language visible in chat OR documented miss; override written manually |
| Path B | OOO vs on-call handled with Calendar + web override; Slack path explicitly deferred |
| Safety | No overrides written to a production primary schedule |

**AI Actions:** 0 for Shift and for manual web overrides.

---

## Slide 40 — §4 Insights Agent — Conversational in Teams

**Key message:** Prove Insights answers MTTR / MTTA / volume questions inside Microsoft Teams. Weekly proactive maturity DMs remain Slack-first — document that gap.

1. Confirm Insights Agent Enabled.
2. Pick one Team/Service you own with real history (sanity-checkable).
3. Open POC Teams channel (or Advance chat).
4. Ask: `@pagerduty How many high urgency incidents were there last week on <ServiceOrTeam>?`
5. Ask: `@pagerduty How has the average time to resolve changed over the past 6 complete months for <Team>?`
6. Ask: `@pagerduty Was MTTA faster this month than last month for <Service>?`
7. Compare each answer to Analytics in the PagerDuty web UI.
8. Optional: Rate AI Response. Document weekly DM Slack gap. Apply any config tips on TEST first.

---

## Slide 41 — §4 Insights Success + Cost / Surface Cheat Sheet

| Check | Pass if |
| --- | --- |
| Chat answer | Number or trend tied to your Team/Service in Teams |
| Sanity | Roughly matches Analytics UI for the same filter |
| Visibility | Channel members can see the `@pagerduty` reply |
| DM gap documented | Notes state weekly proactive DMs are Slack-first |

| Agent | Teams-only demo surface | AI Actions | Honest note |
| --- | --- | --- | --- |
| SRE | Teams `@pagerduty` ask; optional PD web tab | 4 per ask | Early Access in Teams |
| Scribe | Teams meeting URL + advance scribe | ~6/30m + ~2 summary | Strongest Teams-only fit |
| Shift | Path A ask; Path B web + Calendar | 0 | Full coverage DMs need Slack |
| Insights | Teams `@pagerduty` analytics Q&A | 0 | Weekly maturity DMs Slack-first |

---

## Slide 42 — Afternoon Plan + Data Flow + Commands

| Order | Block | Time box |
| --- | --- | --- |
| 0 | Shared Teams enablement | 30–60 min (Admins) |
| 1 | SRE Agent POC | 15–20 min |
| 2 | Scribe Agent POC | 15–20 min (meeting ≤10 min) |
| 3 | Shift Path B (or Path A) | 10–15 min |
| 4 | Insights conversational | 10–15 min |

```
§0 Graph + Authorize + linkUser
  → 1 SRE triage in Teams
  → 2 Scribe on Teams meeting
  → 3 Shift Path B (web/Calendar)
  → 4 Insights Q&A in Teams
Weekly DMs = Slack gap
```

**Type in Teams (not shell):**

| Command / ask | Purpose |
| --- | --- |
| `@PagerDuty linkUser` | Map Teams identity to PD user |
| `graphAuth` | If Delegated-heavy Graph setup |
| `@pagerduty What are some likely root causes?` | SRE triage start |
| `@PagerDuty advance scribe` | Invite Scribe to meeting |
| `@pagerduty How has the average time to resolve changed over the past 6 complete months for <Team>?` | Insights MTTR trend |

---

## Data flow map

```
Dynatrace Problem (+ problem URL in custom_details)
        │
        ▼
PagerDuty Incident  ← hub object (test Service in POC)
        │
        ├── page ──► Human on-call
        ├── SRE ──── triage / runbook / next steps
        ├── Scribe ─ bridge transcript / summary
        ├── Shift ── coverage / override (Slack or Path B)
        └── Insights ─ MTTR / MTTA / volume Q&A
        │
        ▼
Human Resolve → optional SRE service memory → Insights trends later
```

---

## Related files

| File | Role |
| --- | --- |
| `warp /Tasks/19-Dynatrace-PagerDuty-Four-Agents-Whole-Pack-NoFooter.pptx` | Source deck (42 slides) |
| `Daily Files/2026-09-23/10-four-agents-ppt-each-page-explain/` | This guide |
| `Daily Files/2026-09-23/2` … `9` | Prior single-slide explains |
| `Daily Files/2026-08-31/19-dynatrace-pd-four-agents-whole-ppt-nofooter/` | Pack source folder |
| `10.sh` | Optional open / extract helpers (user runs) |

## Commands

See `10.sh` in this folder. Do not run against prod.
