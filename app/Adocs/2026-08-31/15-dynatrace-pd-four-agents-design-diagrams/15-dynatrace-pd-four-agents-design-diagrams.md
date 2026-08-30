# Dynatrace PD Four Agents Design Diagrams

## Decision tree

```
Need ARB-style design diagrams (like Splunk→Dynatrace AS-IS/TO-BE slides)?
  Open the Design Diagrams PPT below
  Want narrative + summary sheet too?
    Pair with seq 14 architecture md + seq 13 narrative PPT
  Regenerate boxes after edit?
    Edit 15_generate_design_diagrams_pptx.py → run with python-pptx venv
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Deliverable | ARB-style **design diagram** PowerPoint for Dynatrace → PagerDuty Four AI Agents |
| File | `15-Dynatrace-PagerDuty-Four-Agents-Design-Diagrams.pptx` |
| Matches | Solution Context AS-IS/TO-BE look from your Splunk→Dynatrace ARB slides |
| Slides | Title, AS-IS, TO-BE, Impacted Platforms, Alignment, HLD, Agent hub, Checklist |
| Pair with | Seq 14 architecture md (text capture) + seq 13 narrative PPT |

---

## Summary

This pack is the visual twin of the Splunk→Dynatrace **Solution Context Diagram** slides, redrawn for the Dynatrace → PagerDuty Four AI Agents design. AS-IS shows Dynatrace → PD → human toil. TO-BE puts PagerDuty Advance (SRE/Scribe/Shift/Insights) in the center hub. Impact and HLD slides show what platforms change and how chat/meeting/calendar attach.

---

## Main content

### Slide list

| # | Slide | Same role as ARB… |
| --- | --- | --- |
| 1 | Title | Cover |
| 2 | AS-IS Solution Context | Slide 7 style (Splunk hub → here PD+human) |
| 3 | TO-BE Solution Context | Slide 8 style (Dynatrace hub → here PD Advance hub) |
| 4 | Impacted Platforms | Slide 9 style (highlight IT/Cloud/Advance) |
| 5 | Alignment stack | Slide 10 style (Ops/IR layers) |
| 6 | Technical HLD | Slide 12 style connectivity |
| 7 | Agent hub detail | Four agents around one incident |
| 8 | Design checklist | POC / board readiness |

### File locations

| Path | Role |
| --- | --- |
| Daily Files `.../15-.../15-Dynatrace-PagerDuty-Four-Agents-Design-Diagrams.pptx` | Main design PPT |
| `15_generate_design_diagrams_pptx.py` | Regenerator |
| Adocs twin | `app/Adocs/2026-08-31/15-dynatrace-pd-four-agents-design-diagrams/` |

### How the three packs fit

| Pack | What |
| --- | --- |
| Seq 14 md | ARB-style **text** architecture capture |
| Seq 13 PPT | Narrative summary / agent detail slides |
| **Seq 15 PPT (this)** | **Visual** AS-IS/TO-BE/Impact/HLD design diagrams |

---

## Data flow map

```
[Your ARB screenshot style]
   AS-IS hub / TO-BE hub / Impact map / HLD
        |
        v
[15_generate_design_diagrams_pptx.py]
        |
        v
[15-Dynatrace-PagerDuty-Four-Agents-Design-Diagrams.pptx]
   AS-IS: Dynatrace → PD → Human toil
   TO-BE: Dynatrace → PD Advance hub (4 agents) → Human decides
```

---

## Related files

| File | Purpose |
| --- | --- |
| [15.sh](./15.sh) | Open / regenerate |
| [15-dynatrace-pd-four-agents-design-diagrams-follow.txt](./15-dynatrace-pd-four-agents-design-diagrams-follow.txt) | Chat-ready |
| Architecture md | `2026-08-31/14-dynatrace-pagerduty-four-agents-architecture/` |
| Narrative PPT | `2026-08-31/13-dynatrace-pagerduty-four-agents-ppt/` |
| Style reference screenshots | Splunk→Dynatrace ARB slides 7–10, 12 |

---

## Commands

See [15.sh](./15.sh).
