# PD AI Teams Third Party Example

```
Need PD AI alert example without “you”?
 → Use named objects: Incident, Dynatrace Problem, Teams channel, Primary, AI Assistant
 → Story in third person only
 → Teams path only (no Slack)
```

| Key point | Detail |
|---|---|
| Style | Third-party objects and named roles — no “you / we / I” |
| Channel | Microsoft Teams only |
| Story id | Incident `INC-48291`, Problem `P-88421`, service `ebroker-api` |
| AI role | Assists after the incident exists; does not replace the page |

## Summary

This example treats people and systems as named objects. The alert opens a PagerDuty incident, Teams shows it, Primary asks the PagerDuty AI Assistant in Teams, then Primary acts in PagerDuty.

---

## Named objects

| Object | Name in this story |
|---|---|
| Monitor | Dynatrace Problem `P-88421` |
| Service | `ebroker-api` |
| Incident | PagerDuty `INC-48291` (P2) |
| Chat | Teams channel `monitoring-2026-prod` |
| Responder | Primary (on-call SRE) |
| Secondary | Secondary (backup on-call) |
| Helper | PagerDuty AI Assistant (Teams) |
| Dependency | `agrex` zipcode path |

---

## Timeline (third person)

### T+0 — Problem creates Incident

```
Dynatrace Problem P-88421
  detects high error rate on ebroker-api (address conversion path)
  → PagerDuty creates INC-48291
  → PagerDuty pages Primary
  → PagerDuty app posts INC-48291 into Teams channel monitoring-2026-prod
```

PagerDuty AI Assistant stays idle until a human prompt appears in Teams.

### T+2 — Primary asks for catch-up

Primary posts in the Teams incident thread:

```
@PagerDuty Catch me up on INC-48291
```

PagerDuty AI Assistant returns (illustrative):

```
INC-48291 — High error rate on ebroker-api (P2)
• Opened 16:05 JST · Acknowledged by Primary
• Source: Dynatrace P-88421
• Related past: INC-47102 (agrex dependency recovery)
• Starter checks:
  1) agrex / zipcode dependency health
  2) recent ebroker-api deploy or config change
  3) log phrase "Address conversion failed…" vs broad 5xx
```

### T+8 — Primary adds a log object and asks causes

Primary posts:

```
Log sample: Address conversion failed.Request to agrex Zipcode
@PagerDuty What are some likely root causes?
```

PagerDuty AI Assistant returns (illustrative):

```
Angles to verify for INC-48291:
1) agrex zipcode dependency latency / 5xx / timeout
2) unusual zip input volume
3) ebroker address-service config or URL change after deploy
4) network path to intraxa host

Confirmation still requires Dynatrace dependency view and live logs.
```

### T+15 — Stakeholder ping; status draft object

Primary posts:

```
@PagerDuty Draft an internal status update for INC-48291
```

PagerDuty AI Assistant returns a draft object:

```
Title: Investigating elevated ebroker address-conversion errors
Impact: zip→address lookup failures / retries on ebroker-api
Started: 16:05 JST
Status: Investigating (acked by Primary)
Evidence so far: Dynatrace P-88421; log phrase Address conversion failed.Request to agrex Zipcode
Next update: 30 minutes
Owner: Primary
```

Primary edits two fields, then posts the final status to the stakeholder Teams channel.

### T+25 — Bridge + Scribe object

Teams meeting for INC-48291 starts. Scribe Agent (if enabled) captures meeting + chat notes.

Primary later posts:

```
@PagerDuty Wrap me up including Scribe notes for INC-48291
```

PagerDuty AI Assistant returns (illustrative):

```
• 16:18 Dynatrace shows agrex latency spike
• 16:22 Decision: wait for dependency recovery; no ebroker-api rollback
• 16:24 Impact scoped to address conversion; payments path separate
• Open action: agrex follow-up; attach runbook link on INC-48291
```

### T+45 — Resolve + PIR draft object

Errors drop. INC-48291 moves to Resolved.

Primary posts:

```
@PagerDuty Draft a post-incident review outline for INC-48291
```

| PIR section | Draft content object |
|---|---|
| What happened | ebroker-api address conversion errors for ~40 minutes |
| Impact | zip→address failures / retries |
| Detection | Dynatrace P-88421 → PagerDuty page under 2 minutes |
| Response | Ack by Primary; dependency check; status draft; no rollback |
| Root cause (draft) | Upstream agrex degradation — mark unconfirmed until evidence locked |
| Follow-ups | Runbook link on INC-48291; dependency SLO discussion |

Primary replaces the root-cause draft with confirmed evidence before PIR publish.

---

## Object interaction map

```
[Dynatrace Problem P-88421]
        |
        v
[PagerDuty INC-48291] ----page----> [Primary]
        |
        +----notify----> [Teams: monitoring-2026-prod]
                              |
                              v
                    [Primary] --prompt--> [PagerDuty AI Assistant]
                              |
                              v
                    [AI reply objects: summary | causes | status | Scribe wrap-up]
                              |
                              v
                    [Primary] --fact-check--> [PagerDuty actions: escalate | resolve]
                              |
                              v
                    [PIR draft object] --edit--> [Final PIR]
```

---

## Paste block for Teams (third person)

```
Detailed example (third person):

Objects: Dynatrace Problem P-88421, PagerDuty INC-48291, service ebroker-api,
Teams channel monitoring-2026-prod, Primary (on-call), PagerDuty AI Assistant.

1) P-88421 creates INC-48291. PagerDuty pages Primary. Teams shows INC-48291.
2) Primary: @PagerDuty Catch me up on INC-48291
   → AI Assistant returns timeline, related incident, starter checks.
3) Primary pastes log phrase Address conversion failed.Request to agrex Zipcode
   and asks likely causes
   → AI Assistant returns a verify checklist (agrex / deploy / input).
4) Primary: @PagerDuty Draft internal status for INC-48291
   → AI Assistant returns a status draft; Primary edits and posts.
5) Optional: Scribe on the Teams bridge → Primary asks wrap-up with Scribe notes.
6) After resolve: AI Assistant returns PIR outline; Primary locks root cause with evidence.

Rule: AI Assistant assists inside Teams after INC exists. The page and the decision stay with PagerDuty + Primary.
```

## Data flow map

```
Problem → Incident + page → Teams notify
  → Primary prompts AI Assistant in Teams
  → AI reply objects
  → Primary acts in PagerDuty
```

## Related files

| File | Role |
|---|---|
| `19-pd-ai-detailed-alert-example/` | Earlier second-person style example |
| `20-pd-ai-teams-only-focus/` | Teams-only standing preference |
| `21.sh` | Dual-write |

## Commands

See [21.sh](21.sh).
