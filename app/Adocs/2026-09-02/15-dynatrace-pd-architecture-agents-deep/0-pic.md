# Pic — Architecture and Four Agents

## Decision tree

```
Dynatrace Problem fired?
  YES → PD Incident created (problem URL in payload)
        │
        ├─ Alert storm? → Event Orchestration / grouping FIRST
        │
        └─ Human paged → which job?
              │
              ├─ Triage / RCA / runbook?     → SRE Agent (4 Actions/ask)
              ├─ Bridge call running?        → Scribe Agent (~6/30m + 2)
              ├─ OOO vs Level-1 on-call?     → Shift Agent (0 Actions)
              └─ MTTR / volume / trends?     → Insights Agent (0 Actions)
                    │
                    └─ Human confirms → Resolve → SRE memory
```

## Data flow (pic style)

```
Dynatrace (detect)
      │
      ▼
PagerDuty Incident (hub)
      │
      ├── page ──► Human
      │
      ├── SRE ────── triage, runbook, past incidents
      ├── Scribe ─── meeting transcript + summary
      ├── Shift ──── coverage / override (Slack full, Teams Path B)
      └── Insights ─ MTTR/MTTA Q&A
      │
      ▼
Resolve → SRE memory → Insights trends later
```
