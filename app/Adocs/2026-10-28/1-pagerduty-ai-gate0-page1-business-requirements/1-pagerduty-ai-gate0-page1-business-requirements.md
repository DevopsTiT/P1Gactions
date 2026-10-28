# PagerDuty AI Gate0 Page1 Business Requirements

```
Gate 0 Business Requirements (1/4)?
 → 1 Business Value Chain ticks
 → 2 Current process (before PD AI)
 → 3 Pains (+ brief positives)
 → Teams only
```

| Key point | Detail |
|---|---|
| Page | Business Requirements **(1/4)** |
| Product | PagerDuty AI in **Microsoft Teams** |

## Summary

Paste-ready Gate 0 page 1: value chain, current Dynatrace→PD→Teams process without AI, and pains.

---

## 1. Business Value Chain

```
[X] Information technology
[X] Operational Excellence and Project Management
[X] Security
[X] Data & AI
[X] Risk management
```

## 2. Current process

**Use case 1 — Incident response (on-call):**  
Dynatrace problem → PagerDuty incident + page → Teams channel notify → Primary acks in PagerDuty → manual catch-up (Dynatrace + PD + Teams) → hand-written status / PIR.

**Solutions today:** Dynatrace, PagerDuty, Microsoft Teams. No PagerDuty AI yet.

**Use case 2 — Mid-incident join:**  
Late joiner rebuilds context from Teams + PD + Dynatrace without AI summary.

## 3. Pains

- Slow catch-up / handoff across tools
- Manual status and PIR writing under pressure
- Bridge/chat context not tied into an incident assist layer
- On-call time spent on documentation toil instead of fix

**Positives to keep:** PD paging + Teams notify already work; Dynatrace stays the detector.

## Data flow map

```
Dynatrace → PagerDuty (page) → Teams notify → manual catch-up / status / PIR
(no PagerDuty AI yet)
```

## Related files

| File | Role |
|---|---|
| `1.sh` | Dual-write |
| `2026-10-22/21-pd-ai-teams-third-party-example/` | After-AI example |

## Commands

See [1.sh](1.sh).
