# Dynatrace PD Four Agents Whole Pack No Footer

## Decision tree

```
Need the whole PPT without any bottom text?
  Open the NoFooter deck below
  Still see a line at the bottom?
    Wrong file — use seq 19, not seq 18
  Want page numbers later?
    PowerPoint Insert → Header & Footer (your choice)
```

---

## Short takeaway

| Key point | Detail |
| --- | --- |
| Deliverable | Same **42-slide** whole pack as seq 18, **with no footer and no page numbers** |
| File | `19-Dynatrace-PagerDuty-Four-Agents-Whole-Pack-NoFooter.pptx` |
| Removed | Bottom line `Dynatrace to PagerDuty Four AI Agents — Whole Pack` and `n / 42` |
| Content | Part A narrative + Part B design diagrams + Part C Teams-only POC |

---

## Summary

New whole-pack PowerPoint combining seq 13, 15, and 17. Bottom band is empty on every slide — no pack name, no AXA/ARB template text, no page counters.

---

## Main content

### Structure (same as seq 18)

| Slides | Part |
| --- | --- |
| 1–2 | Cover + Agenda |
| 3–14 | Part A — Narrative (seq 13) |
| 15–22 | Part B — Design diagrams (seq 15) |
| 23–42 | Part C — Teams-only POC (seq 17) |

### File locations

| Path | Role |
| --- | --- |
| Daily Files `.../19-.../19-Dynatrace-PagerDuty-Four-Agents-Whole-Pack-NoFooter.pptx` | Open this |
| `19_combine_nofooter_pptx.py` | Regenerator |
| Adocs twin | `app/Adocs/2026-08-31/19-dynatrace-pd-four-agents-whole-ppt-nofooter/` |
| Old with footer | seq 18 — do not use if you want a clean bottom |

---

## Data flow map

```
seq 13 + seq 15 + seq 17
        |
        v
19_combine_nofooter_pptx.py
  (strip all bottom text boxes)
        |
        v
19-...-NoFooter.pptx   ← no footer, no page numbers
```

---

## Related files

| File | Purpose |
| --- | --- |
| [19.sh](./19.sh) | Open / regenerate |
| [19-dynatrace-pd-four-agents-whole-ppt-nofooter-follow.txt](./19-dynatrace-pd-four-agents-whole-ppt-nofooter-follow.txt) | Chat-ready |

---

## Commands

See [19.sh](./19.sh).
