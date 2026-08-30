# Dynatrace PD Four Agents Clean Design PPT

## Decision tree

```
Need design diagrams without board-template branding?
  Open the Clean Design PPT below
  Still see "AXA Japan ARB Template style" in footer?
    That is the OLD seq 15 deck — use seq 16 instead
  Want narrative or full architecture text too?
    Pair with seq 14 md + seq 13 narrative PPT
  Regenerate after edit?
    Edit 16_generate_clean_design_pptx.py → run with local .venv
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Deliverable | **New clean** design PowerPoint (no AXA / ARB template footer) |
| File | `16-Dynatrace-PagerDuty-Four-Agents-Clean-Design.pptx` |
| Slides | Title, AS-IS, TO-BE, Technical HLD, Agent Hub |
| Footer | Only: `Dynatrace to PagerDuty Four AI Agents — Design` plus page number |
| Do not use | Seq 15 design PPT if you want zero board-template wording |

---

## Summary

This deck is a fresh design-pack PowerPoint for Dynatrace → PagerDuty Four AI Agents. Same useful diagrams (AS-IS, TO-BE hub, HLD, agent hub), but the footer and cover never say AXA, ARB Template, or ARB-style. Use this when sharing outside a formal board template context.

---

## Main content

### What was removed (on purpose)

| Old (seq 15) | New (seq 16) |
| --- | --- |
| Footer: `AXA Japan ARB Template style · …` | Footer: deck name only |
| Cover: `ARB-style AS-IS / TO-BE…` | Cover: agent names only |
| Impact / Alignment / Checklist slides | Dropped for a short design pack |
| Board-template claims | None |

### Slide list

| # | Slide | What you see |
| --- | --- | --- |
| 1 | Title | Dynatrace to PagerDuty Four AI Agents |
| 2 | AS-IS | Dynatrace → PD → human toil / pain |
| 3 | TO-BE | Red hub = PagerDuty Advance (four agents) |
| 4 | Technical HLD | Responder/Admin ↔ PD ↔ Dynatrace ↔ chat/meeting |
| 5 | Agent Hub | SRE / Scribe / Shift / Insights around one incident |

### File locations

| Path | Role |
| --- | --- |
| Daily Files `.../16-.../16-Dynatrace-PagerDuty-Four-Agents-Clean-Design.pptx` | Open this |
| `16_generate_clean_design_pptx.py` | Regenerator |
| Adocs twin | `app/Adocs/2026-08-31/16-dynatrace-pd-four-agents-clean-design-ppt/` |

### How packs fit

| Pack | What |
| --- | --- |
| **Seq 16 (this)** | Clean visual design PPT (use for sharing) |
| Seq 15 | Older design PPT — still has template-style footer text |
| Seq 14 md | Architecture text capture |
| Seq 13 PPT | Narrative / agent detail slides (also has ARB-style footer) |

---

## Data flow map

```
Dynatrace Problem
      |
      v
PagerDuty Incident  ----->  [Advance Agents]
      |                      SRE / Scribe / Shift / Insights
      v
Human decides (blast radius stays with people)
```

---

## Related files

| File | Purpose |
| --- | --- |
| [16.sh](./16.sh) | Open / regenerate |
| [16-dynatrace-pd-four-agents-clean-design-ppt-follow.txt](./16-dynatrace-pd-four-agents-clean-design-ppt-follow.txt) | Chat-ready |
| Architecture md | `2026-08-31/14-dynatrace-pagerduty-four-agents-architecture/` |

---

## Commands

See [16.sh](./16.sh).
