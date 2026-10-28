# PagerDuty AI Gate0 Page1 Business Requirements

```
Gate 0 Business Requirements (1/4)?
 → 1 Business Value Chain ticks
 → 2 Current process (before PD AI)
 → 3 Pains (+ brief positives of current process)
 → Teams only (no Slack)
```

| Key point | Detail |
|---|---|
| Page | Business Requirements **(1/4)** — Value Chain / Current process / Pains |
| Product | PagerDuty AI (Advance) in **Microsoft Teams** |
| Scope | Incident response assist after the page — not a second pager |

## Summary

Paste-ready content for the first Gate 0 slide. Value chain is IT + Ops Excellence + Security. Current process is Dynatrace → PagerDuty → Teams without AI. Pains are catch-up time, status writing, and scattered context.

---

## 1. Business Value Chain

Tick (X) the applicable choices:

| Choice | Tick |
|---|---|
| Information technology | **X** |
| Operational Excellence and Project Management | **X** |
| Security | **X** |
| Data & AI | **X** (enabler — generative assist on incidents) |
| Risk management | **X** (optional — reduces MTTR / coordination risk) |
| Other | _leave blank unless sponsor wants a named LOB_ |

**Paste line for the form:**

```
[X] Information technology
[X] Operational Excellence and Project Management
[X] Security
[X] Data & AI
[X] Risk management
```

---

## 2. Current process

### Use case 1 — Major / high-priority incident response (on-call)

**Tell us about the current business process**

1. Monitoring (Dynatrace or equivalent) detects a problem and creates or updates a **PagerDuty incident**.
2. PagerDuty **pages** the Primary on-call (phone / push / SMS).
3. The PagerDuty app posts the incident into the connected **Microsoft Teams** channel.
4. Primary acknowledges in PagerDuty, then gathers context manually: Dynatrace problem view, recent changes, related past incidents, Teams chat history, optional bridge notes.
5. Primary writes status updates for stakeholders by hand.
6. After resolve, Primary (or the team) drafts post-incident review content from memory, chat, and tool timelines.

**Which current solution(s) are you using**

| Layer | Current solution |
|---|---|
| Detect | Dynatrace (problems / alerts) |
| Page / incident system of record | PagerDuty |
| Responder collaboration | Microsoft Teams (PagerDuty app) |
| Optional bridge | Teams meeting |
| AI assist today | **None** (PagerDuty AI not in the live path yet) |

### Use case 2 — Mid-incident join / handoff

Same stack. A late joiner (Secondary or another SRE) opens Teams + PagerDuty + Dynatrace and rebuilds the timeline by reading messages and tool UIs — no single “catch me up” assist.

---

## 3. Pains

**Pains of the current process (before PagerDuty AI)**

- **Time:** Primary and late joiners spend many minutes reconstructing timeline, related incidents, and “what was already tried” across Dynatrace, PagerDuty, and Teams.
- **Time / toil:** Status updates and post-incident narratives are written from scratch under pressure; quality varies by who is on-call.
- **Technical / process:** Meeting and chat context are not automatically attached to the incident record; Scribe-style capture is missing.
- **Budget / opportunity cost:** Highly paid on-call time is spent on copy-paste and catch-up instead of diagnosis and fix.
- **Risk:** Incomplete handoffs increase MTTR and stakeholder confusion when multiple people rotate through the channel.

**Positive aspects of the current process (keep)**

- PagerDuty already pages correctly and is the system of record for ack / escalate / resolve.
- Teams already receives incident notifications when the PD app is connected.
- Dynatrace remains the source of technical signals; that path does not need to be replaced.

---

## Confluence / slide paste block (compact)

```
1. Business Value Chain
[X] Information technology
[X] Operational Excellence and Project Management
[X] Security
[X] Data & AI
[X] Risk management

2. Current process
Use case 1 — Incident response (on-call):
Dynatrace problem → PagerDuty incident + page → Teams channel notify
→ Primary acks in PagerDuty → manual catch-up (Dynatrace + PD + Teams)
→ hand-written status / PIR.

Solutions today: Dynatrace, PagerDuty, Microsoft Teams. No PagerDuty AI yet.

Use case 2 — Mid-incident join:
Late joiner rebuilds context from Teams thread + PD + Dynatrace without AI summary.

3. Pains
• Slow catch-up / handoff across tools
• Manual status and PIR writing under pressure
• Bridge/chat context not tied into the incident assist layer
• On-call time spent on documentation toil instead of fix
Positives to keep: PD paging + Teams notify already work; Dynatrace stays the detector.
```

## Data flow map (current = before AI)

```
[Dynatrace Problem]
       |
       v
[PagerDuty Incident] ----page----> [Primary]
       |
       +----notify----> [Teams channel]
                              |
                              v
                    Manual catch-up / status / PIR
                    (no PagerDuty AI Assistant yet)
```

## Related files

| File | Role |
|---|---|
| `2026-10-22/21-pd-ai-teams-third-party-example/` | Runtime example (after AI) |
| `2026-10-22/20-pd-ai-teams-only-focus/` | Teams-only rule |
| `2026-10-21/10-pd-ai-slack-teams-data-flow/` | Setup wiring (use Teams parts) |
| `1.sh` | Dual-write |

## Commands

See [1.sh](1.sh).
