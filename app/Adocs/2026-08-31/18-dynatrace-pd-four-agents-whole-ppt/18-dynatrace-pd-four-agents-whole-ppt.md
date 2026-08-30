# Dynatrace PD Four Agents Whole Pack PPT

## Decision tree

```
Need one PPT that covers narrative + design diagrams + Teams POC?
  Open the Whole Pack below (42 slides)
  Only need design boxes?
    Use Part B section, or open seq 15 alone
  Only need Teams click path?
    Use Part C section, or open seq 17 alone
  Still see AXA / ARB Template footer?
    Wrong file — this pack uses a clean whole-pack footer
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Deliverable | **One combined** PowerPoint (seq 13 + seq 15 + seq 17) |
| File | `18-Dynatrace-PagerDuty-Four-Agents-Whole-Pack.pptx` |
| Slides | **42** (title, agenda, 3 part dividers, then all content) |
| Part A | Narrative architecture from seq 13 |
| Part B | Design diagrams from seq 15 |
| Part C | Teams-only POC runbook from seq 17 |
| Footer | `Dynatrace to PagerDuty Four AI Agents — Whole Pack` (no AXA/ARB branding) |

---

## Summary

This whole pack merges the narrative architecture deck, the visual design-diagrams deck, and the detailed Teams-only POC runbook into a single PowerPoint. Use Part A + B for design review. Use Part C for a hands-on Teams-only afternoon.

---

## Main content

### Structure

| Part | Source | Content |
| --- | --- | --- |
| Cover + Agenda | New | How to use the pack |
| **A — Narrative** | seq 13 | Summary, AS-IS/TO-BE story, agents, cost/safety, afternoon |
| **B — Design diagrams** | seq 15 | Solution Context boxes, Impact, Alignment, HLD, hub, checklist |
| **C — Teams-only POC** | seq 17 | §0 enablement through Insights click path |

### Slide index (high level)

| Range | Section |
| --- | --- |
| 1–2 | Whole-pack title + agenda |
| 3–14 | Part A narrative (divider + 11 content slides) |
| 15–22 | Part B design diagrams (divider + 7 content slides) |
| 23–42 | Part C Teams POC (divider + 19 content slides) |

### File locations

| Path | Role |
| --- | --- |
| Daily Files `.../18-.../18-Dynatrace-PagerDuty-Four-Agents-Whole-Pack.pptx` | Open this |
| `18_combine_whole_pptx.py` | Re-merge from seq 13/15/17 |
| Adocs twin | `app/Adocs/2026-08-31/18-dynatrace-pd-four-agents-whole-ppt/` |

### Inputs combined

| Input PPT | Path |
| --- | --- |
| Narrative | `13-.../13-Dynatrace-PagerDuty-Four-AI-Agents-ARB-style.pptx` |
| Design diagrams | `15-.../15-Dynatrace-PagerDuty-Four-Agents-Design-Diagrams.pptx` |
| Teams-only POC | `17-.../17-PagerDuty-Four-Agents-Teams-Only-POC.pptx` |

---

## Data flow map

```
[seq 13 narrative PPT] ──┐
[seq 15 design PPT] ─────┼──> 18_combine_whole_pptx.py
[seq 17 Teams POC PPT] ──┘              │
                                        v
              18-Dynatrace-PagerDuty-Four-Agents-Whole-Pack.pptx
                 Part A → Part B → Part C
```

---

## Related files

| File | Purpose |
| --- | --- |
| [18.sh](./18.sh) | Open / regenerate |
| [18-dynatrace-pd-four-agents-whole-ppt-follow.txt](./18-dynatrace-pd-four-agents-whole-ppt-follow.txt) | Chat-ready |
| Seq 13 / 15 / 17 | Source decks |

---

## Commands

See [18.sh](./18.sh).
