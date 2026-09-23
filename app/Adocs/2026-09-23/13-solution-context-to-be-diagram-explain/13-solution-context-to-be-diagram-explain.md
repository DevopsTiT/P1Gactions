# Solution Context TO-BE Diagram Explain

```
What is this slide?
  → Target picture after Advance agents are on
  → Same Dynatrace → PagerDuty path as AS-IS
  → Plus four agents beside the human

Read left → center → right → yellow box
  Dynatrace (± EO) + Ops HQ
       → PagerDuty Incident hub
       → SRE / Scribe / Shift / Insights
       → Human decides
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What it is | **TO-BE** architecture: how the system should work with Advance agents |
| Hub object | **PagerDuty Incident** (not the Dynatrace Problem alone) |
| New layer | Four Advance agents assist **after** Dynatrace creates the incident |
| Optional piece | **Event Orchestration (EO)** cuts noise before agents run |
| Hard rule | Humans confirm remediations and own blast radius |

## Summary

TO-BE keeps Dynatrace as the eyes (detect) and PagerDuty as the pager (incident + page). What changes is an **assist layer**: SRE, Scribe, Shift, and Insights sit on the incident hub and help the human. Agents suggest; humans decide. Optional EO reduces junk incidents so agents (and people) waste less time.

## Investigation

User shared **Solution Context Diagram — TO-BE** (whole pack Part B style). Mapped every box: left inputs, red hub, four agent cards, yellow human box. Cross-checked against seq 8 (earlier TO-BE explain) and seq 10 Slide 17.

## Result

Use this slide in design review to answer “what changes vs today?” Pair with the AS-IS slide to show the gap you are closing.

---

## 1) Key Message (top box)

| Claim | Plain English |
| --- | --- |
| Four AI Agents assist beside the human | Agents help; they do not replace on-call |
| After Dynatrace creates the incident | Dynatrace is still **ingress** — it opens the PD incident |
| Optional Event Orchestration | Noise filter **before** a full incident / agent work |
| Humans confirm remediations | No silent prod change; you own risk |

---

## 2) Left side — what feeds the hub

| Box | What it is | Why you care |
| --- | --- | --- |
| **Dynatrace** (green) | Sends Problem + **problem URL** in the PD payload | Deep-link back to the monitoring problem; put URL early in `custom_details` |
| **Optional EO** | Event Orchestration: route / pause / group | Fewer junk pages so SRE Agent is not drowning in noise |
| **Ops (HQ)** | Humans in Teams / PD web; OneAccount-style access | Where responders and commanders work day to day |

**Beginner tip:** EO is optional. If you have no alert storms, you can skip it for a first POC. If Dynatrace (or other tools) spam pages, EO is worth enabling before you lean hard on agents.

---

## 3) Center — PagerDuty Incident hub

| Idea | What it means |
| --- | --- |
| Incident hub | One PD incident is the shared object everyone and every agent attaches to |
| Advance AI Agents listed inside | SRE · Scribe · Shift · Insights live **on** that incident |
| Not a second monitoring tool | Agents do not replace Dynatrace Davis; they help **response** |

```
Dynatrace Problem (+ URL)
        │
        ▼
[optional EO: route / pause / group]
        │
        ▼
PagerDuty Incident hub  ← agents attach here
        │
        ├── page human
        └── assist with four agents
```

---

## 4) Right side — four agent cards

| Agent | Job on this diagram | Cost on slide |
| --- | --- | --- |
| **SRE** | Triage + runbook | **4 Actions / ask** |
| **Scribe** | Meeting transcript | **~6/30m + 2** (summary) |
| **Shift** | Coverage / override | **0 Actions** |
| **Insights** | MTTR Q&A | **0 Actions** |

| Agent | When you use it in TO-BE |
| --- | --- |
| SRE | First minutes after page — likely causes, runbook, next steps |
| Scribe | Bridge / war-room call — notes without typing everything |
| Shift | Before or between pages — OOO vs on-call coverage |
| Insights | After / between incidents — trends for leadership |

You can use **more than one** agent on the same incident (for example SRE + Scribe on a big fire).

---

## 5) Yellow box — Human decides

| Duty | What it means | Why it is yellow |
| --- | --- | --- |
| Confirm remediations | Approve or decline suggested fixes | AI can be wrong |
| Own blast radius | You are accountable for how wide the change hits | Agents do not take the page |
| Resolve → SRE memory | Closing can save learnings for that Service | Improves later triage |

**Blast radius** = how much can break if the fix is wrong (one pod vs whole region).

---

## 6) TO-BE vs AS-IS (one glance)

| Layer | AS-IS | TO-BE |
| --- | --- | --- |
| Detect | Dynatrace | Dynatrace (same) |
| Noise | Often none / manual | Optional EO |
| Page | PagerDuty | PagerDuty (same) |
| Assist | Human only (dig docs, type notes, CSV) | Four Advance agents |
| Decide | Human | Human (still — now with better help) |

---

## 7) Common misreads of this slide

| Misread | Correct reading |
| --- | --- |
| “Agents replace Dynatrace” | No — Dynatrace still creates the signal / incident |
| “EO is mandatory” | No — optional; use when noise is a problem |
| “Agents auto-fix prod” | No — yellow box: human confirms |
| “One agent per company” | No — pick by job; multiple agents per incident OK |
| “Insights runs during the fire only” | Mostly after / between; SRE/Scribe are the live-fire pair |

---

## Data flow map

```
Dynatrace (Problem + problem URL in PD payload)
        │
        ├─► Optional EO (route / pause / group)
        │
        ▼
PagerDuty Incident hub
   Advance: SRE · Scribe · Shift · Insights
        │
        ├─► Ops HQ (Teams / PD web)
        │
        ▼
Human decides
  confirm remediations · own blast radius · Resolve → SRE memory
```

---

## Related files

| File | Role |
| --- | --- |
| Whole pack Slide 17 (Part B) | This diagram |
| `8-solution-context-to-be-explain/` | Earlier TO-BE narrative slide explain |
| `7-solution-context-as-is-explain/` | AS-IS pair |
| `10-four-agents-ppt-each-page-explain/` | Full 42-page guide |
| `13.sh` | Optional open helpers (user runs) |

## Commands

See `13.sh`. No prod changes required to *read* this diagram.
