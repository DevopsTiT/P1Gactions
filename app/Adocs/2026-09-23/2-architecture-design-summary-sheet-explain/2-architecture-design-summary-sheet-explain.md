# Architecture Design Summary Sheet Explain

```
What is this slide?
  → One-page ARB-style summary of Dynatrace → PagerDuty Advance
  → Four AI agents help humans after the page fires
  → Test only; human confirms remediations
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What the slide is | Architecture Design **Summary Sheet** for Dynatrace + PagerDuty Advance |
| Goal | Prove DT Problems become clean PD incidents, then 4 agents help responders |
| Four agents | SRE triage, Scribe bridge, Shift coverage, Insights analytics |
| Safety | Test Service / test schedule only; human must confirm remediations |

## Summary

This slide is the “elevator pitch” architecture page from your Dynatrace–PagerDuty Four Agents deck. Dynatrace detects; PagerDuty pages; the four Advance agents reduce toil (docs, notes, coverage, trends). It is not the Dynatrace Workflow YAML itself — it sits **after** the page.

Source image: Architecture Design Summary Sheet (from the Four Agents PPT pack).

---

## Investigation

User shared the Architecture Design Summary Sheet slide and asked to explain it. Mapped each table row to beginner SRE language and tied it to Dynatrace → PD → four agents.

## Result

Read row-by-row below. Use the flow diagram for the happy path.

---

## 1) What this slide is for

| Idea | What it means |
| --- | --- |
| Summary Sheet | One table that ARB / stakeholders can scan quickly |
| Architecture Design | How Dynatrace and PagerDuty Advance fit together |
| Not a runbook | It states *what* and *why*; click-steps live on later POC slides |

---

## 2) Row-by-row explain

### Objective

| Plain English | Detail |
| --- | --- |
| What you are proving | Dynatrace Problems → clean PagerDuty incidents |
| Then what | Four Advance agents help the human who got paged |

“Clean” means a proper PD incident on the right Service, not a noisy mess.

### Background (WHY)

| Pain today | Agent idea |
| --- | --- |
| Dynatrace finds the Problem | Already solved by DT |
| Humans dig docs | SRE Agent helps triage |
| Humans take meeting notes | Scribe Agent |
| Humans fix on-call coverage | Shift Agent |
| Humans report trends | Insights Agent |

**Toil** = repetitive manual work that does not need a senior brain every time.

### Design overview (the pipeline)

```
Dynatrace Problem
  → PD Service (optional Event Orchestration)
  → page on-call
  → SRE triage / Scribe bridge / Shift coverage / Insights analytics
```

| Stage | What happens |
| --- | --- |
| Dynatrace Problem | Detection (your workflows/notifications can create/sync the PD side) |
| PD Service | Where the incident lands; Event Orchestration can route/suppress if used |
| Page on-call | Human gets woken (classic PD job) |
| Four agents | Assist **after** the page — triage, notes, coverage, analytics |

### Not one of the four

| Item | Why called out |
| --- | --- |
| Advance Assistant (router) | Chat entry / router — not counted as one of the four |
| Event Intelligence | Noise reduction / grouping — related product, not one of the four agents |
| PIR drafts | Post-incident review help — useful, but not in the “four agents” set on this sheet |

So if someone says “we have 4 AI agents,” they mean **SRE / Scribe / Shift / Insights** only.

### Cloud / SaaS

| Platform | Role |
| --- | --- |
| Dynatrace SaaS | Detect Problems |
| PagerDuty Advance | License tier that includes these AI agents |

You need **Advance** entitlement — not only a basic PD account.

### Chat

| Path | What works |
| --- | --- |
| Teams and/or Slack | Connect chat so agents can talk in channels |
| Teams-only | Full Q&A for **SRE, Scribe, Insights** |
| Slack-first | **Shift** coverage DMs work best on Slack |

Matches your earlier Teams-only POC notes: Shift is the awkward one without Slack.

### Cost model (AI Actions)

| Agent | Cost on the slide |
| --- | --- |
| SRE | 4 Actions per ask |
| Scribe | ~6 per 30 minutes + 2 for summary |
| Shift | 0 |
| Insights | 0 |

Actions are a usage meter for the paid AI features (SRE/Scribe). Shift/Insights called out as 0 on this sheet.

### Safety

| Rule | Meaning |
| --- | --- |
| Test Service / test schedule only | Do not page production on-call for demos |
| Human confirms remediations | Agents suggest; people approve before change/rollback |

---

## 3) How this fits what you already built

| Your earlier work | Where it sits on this slide |
| --- | --- |
| Dynatrace Problem → PD Events API / notification | “Dynatrace Problem → PD Service → page on-call” |
| ServiceNow INC workflows | **Not on this slide** — parallel ticket path |
| Four agents PPT / POC | Everything after “page on-call” |

```
Detect (Dynatrace)
  → Ticket (ServiceNow)     [your Connector pack — separate]
  → Page (PagerDuty)        [this slide]
  → Assist (4 Advance agents) [this slide]
```

---

## 4) Mini decision tree from the slide

```
Need detection?     → Dynatrace
Need to wake someone? → PagerDuty page
Need triage help?   → SRE Agent
Need bridge notes?  → Scribe Agent
Need coverage fix?  → Shift Agent (Slack-first)
Need trends/MTTR?   → Insights Agent
Demo safely?        → Test Service only + human confirm
```

---

## Data flow map

```
Dynatrace Problem
  → PagerDuty Service (+ optional Event Orchestration)
  → Page on-call (human)
  → Assist:
       SRE (triage) | Scribe (bridge notes)
       Shift (coverage) | Insights (analytics)
Safety: test only; human confirms remediations
```

## Related files

| Path | Why |
| --- | --- |
| `../1-pagerduty-four-ai-agent-ppt-location/` | Where the PPT lives |
| `Daily Files/2026-08-31/19-...NoFooter.pptx` | Source deck |
| `Daily Files/2026-08-25/8-pagerduty-ai-agents-detailed/` | Agent details |
| `2.sh` | Paths |

## Commands

See `2.sh` in this folder.
