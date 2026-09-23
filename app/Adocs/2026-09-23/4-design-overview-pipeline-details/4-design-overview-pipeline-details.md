# Design Overview Pipeline Details

```
Dynatrace Problem
  → PD Service (optional Event Orchestration)
  → page on-call
  → SRE triage / Scribe bridge / Shift coverage / Insights analytics
```

## Short takeaway

| Stage | What it does | Who owns it |
| --- | --- | --- |
| Dynatrace Problem | Detects “something is wrong” | Dynatrace Davis |
| PD Service (+ optional EO) | Turns that into a PD incident on the right service | PagerDuty |
| Page on-call | Wakes a human | PD escalation / schedule |
| Four agents | Help after the page (toil cutters) | PagerDuty Advance |

## Summary

This line is the **happy-path architecture** on your Summary Sheet. Detection → incident home → human page → AI assist. Event Orchestration is optional routing/noise control before or as the incident is handled. The four agents do **not** replace the page; they help the person who got paged.

---

## Investigation

User asked for details on the Design overview pipeline from the Architecture Design Summary Sheet.

## Result

Explain each arrow as a real stage: inputs, outputs, options, failures, and how it ties to your Dynatrace→PD work.

---

## 1) Stage A — Dynatrace Problem

| Idea | What it means | Example |
| --- | --- | --- |
| Problem | Davis-grouped outage object | `P-240917001` checkout failure rate |
| Status | OPEN / CLOSED | Drives create vs resolve style automation |
| Output of this stage | “We know something is wrong” + link/context | Problem URL, severity, entities, tags |

### How it can reach PagerDuty

| Path | What it is | In your packs |
| --- | --- | --- |
| Workflow JS → Events API | `POST /v2/enqueue` trigger | Your OPEN workflow PD task |
| Classic Problem notification | Built-in PD notification type | Alternate / older path |
| Custom webhook | Other automation | Possible but not required |

**Plain English:** This stage is **detection**. Nothing is paged yet until PD accepts an event/incident.

### What must be true

| Check | Why |
| --- | --- |
| Monitoring + tags | Reliable Problem |
| Allowlist `events.pagerduty.com` (if Workflow fetch) | Outbound works |
| Stable `dedup_key` (e.g. `dt-problem-<id>`) | Open/close sync |

---

## 2) Stage B — PD Service (optional Event Orchestration)

### PD Service

| Idea | What it means | Why you care |
| --- | --- | --- |
| Service | PD “mailbox” for one app/team (e.g. EIP Checkout) | Owns integration key, escalation, urgency |
| Incident | Ticket-like object responders work in PD | What you ack/resolve |
| Integration | Events API v2 key on that Service | How Dynatrace opens the alert |

**Fake example:** Service `poc-pd-ai-agents-test` or prod `eip-checkout` with routing key `R03AMPLE…`.

### Optional Event Orchestration (EO)

| Idea | What it means | Why “optional” |
| --- | --- | --- |
| Event Orchestration | PD rules engine on incoming events | You can page without it |
| Typical uses | Route by payload, suppress noise, change urgency, fan-in | Enrich/clean before human noise |
| If skipped | Event goes straight to the Service’s normal behavior | Simpler POC |

```
Dynatrace event
  → [optional EO rules: suppress / route / enrich]
  → Service creates/updates incident
```

| When to use EO | When to skip (first) |
| --- | --- |
| Many sources, need routing | Single test Service POC |
| Heavy noise | You already filter in Dynatrace |
| Different urgency by tag | Keep one escalation path |

---

## 3) Stage C — Page on-call

| Idea | What it means | Example |
| --- | --- | --- |
| Page | Notify the current on-call via app/SMS/phone | 02:15 phone rings |
| Escalation policy | Who first, who next if no ack | L1 → L2 after 5 min |
| Schedule | Who is on-call this week | Alice primary |
| Ack | Human claims it; stops further escalate (for now) | 02:16 Ack |

**Plain English:** This is the classic PagerDuty job — **wake a person**. Agents have not replaced this step on the slide.

### Failure modes at this stage

| Symptom | Likely cause |
| --- | --- |
| INC/event in PD, no ring | Wrong escalation / quiet hours / wrong contact |
| Wrong team | Wrong Service / EO route / Dynatrace routing key |
| Never stops paging | No ack; or resolve never sent |

---

## 4) Stage D — Four agents (after the page)

Order on the slide is not a strict sequence of four hops. It is **four assist modes** available once there is an incident + human.

| Agent | Role on the pipeline | When you use it |
| --- | --- | --- |
| **SRE triage** | Dig docs / likely cause / runbook | Active incident, need direction fast |
| **Scribe bridge** | Take notes on the war-room call | Bridge meeting started |
| **Shift coverage** | Fix who is on-call | OOO / conflict / need substitute |
| **Insights analytics** | Report trends | Afterward or weekly — not only during the fire |

```
Page fires
  ├─ Now: SRE (triage)
  ├─ If bridge: Scribe
  ├─ If schedule broken: Shift (often outside the acute minute)
  └─ Later: Insights (trends / noise)
```

### Chat placement

| Agent | Teams | Slack |
| --- | --- | --- |
| SRE | Q&A OK | OK |
| Scribe | OK | OK |
| Insights | Q&A OK | OK (+ some nudges Slack-oriented) |
| Shift | Limited | **Slack-first** for coverage DMs |

### Cost reminder (from Summary Sheet)

| Agent | AI Actions |
| --- | --- |
| SRE | 4 / ask |
| Scribe | ~6 / 30 min + 2 summary |
| Shift | 0 |
| Insights | 0 |

---

## 5) Full pipeline with fake timeline

| Time | Stage | What happens |
| --- | --- | --- |
| 02:14 | Dynatrace | Error rate rises |
| 02:15 | Dynatrace Problem | `P-240917001` OPEN |
| 02:15 | PD Service | Events API trigger → incident on `eip-checkout` (EO optional) |
| 02:15 | Page | On-call phone rings |
| 02:16 | Human | Ack |
| 02:17 | SRE Agent | “Likely causes? runbook?” |
| 02:25 | Scribe | Bridge call transcribed |
| 02:40 | Fix + DT close | PD resolve (automation or human) |
| Next week | Shift / Insights | Coverage gap; MTTR question |

---

## 6) How this relates to ServiceNow (your other path)

| Path | Role |
| --- | --- |
| This pipeline | **Page + AI assist** |
| Dynatrace → SNOW Connector | **Official ticket** |

They run in parallel in your broader design:

```
Dynatrace Problem
  ├─► PD Service → page → agents     (this line)
  └─► SNOW INC (create/resolve)      (Connector workflows)
```

The Summary Sheet focuses on the PD + agents branch only.

---

## 7) Safety on this pipeline

| Rule | Where it applies |
| --- | --- |
| Test Service / test schedule | Especially stages B–D in POC |
| Human confirms remediations | After SRE suggestions — before prod change |
| Do not skip the page | Agents assist responders; they are not the pager |

---

## 8) Mini decision tree

```
No Problem in Dynatrace?
  → Fix monitoring / Davis (Stage A)

Problem but nothing in PD?
  → Routing key, allowlist, Service, EO suppress? (A→B)

Incident but nobody woken?
  → Escalation / schedule / contacts (C)

Woken but stuck digging docs?
  → SRE Agent (D)

Bridge with no notes?
  → Scribe (D)

Schedule hole?
  → Shift (D)

Need MTTR / noise story?
  → Insights (D)
```

---

## Data flow map

```
[A] Dynatrace Problem
        │
        ▼
[B] PD Service
     (+ optional Event Orchestration)
        │
        ▼
[C] Page on-call ──► Human Ack
        │
        ▼
[D] Assist (any / as needed)
     SRE triage
     Scribe bridge
     Shift coverage
     Insights analytics
```

## Related files

| Path | Why |
| --- | --- |
| `../2-architecture-design-summary-sheet-explain/` | Whole summary sheet |
| `../3-why-agents-cut-toil-details/` | Why agents exist |
| `Daily Files/2026-08-25/9-pagerduty-four-agents-poc-examples/` | Per-agent POC |
| `4.sh` | Paths |

## Commands

See `4.sh` in this folder.
