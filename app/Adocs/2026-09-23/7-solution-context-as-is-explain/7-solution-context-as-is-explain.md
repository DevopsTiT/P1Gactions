# Solution Context As Is Explain

```
AS-IS today
  Dynatrace (detect) → PagerDuty (page) → Human on-call (toil) → Pain
Gap: middle work still mostly human
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What this slide is | **AS-IS** (current state) before four Advance agents |
| What already works | Dynatrace detects; PagerDuty pages |
| What hurts | Human still does triage, notes, coverage, trends by hand |
| Why it matters | Sets up the TO-BE story (agents cut that middle toil) |

## Summary

This slide says the monitoring and paging layers are fine. The bottleneck is the **human middle**: digging docs, typing notes, fixing coverage, exporting CSVs for trends. That toil drives slow MTTA/MTTR, missed notes, and spreadsheet chaos. The four agents are proposed to shrink that middle — not to replace Dynatrace or PagerDuty.

---

## Investigation

User shared the “Solution Context — AS-IS” slide and asked to explain it.

## Result

Explain key message, four boxes, bottom gap line, and how it links to the TO-BE / four agents design.

---

## 1) What “AS-IS” means

| Term | What it means | Why you care |
| --- | --- | --- |
| AS-IS | How work runs **today** | Problem statement for ARB / design |
| TO-BE (later slides) | Target with agents | Contrast after you understand pain |
| Solution Context | Where this design sits in the stack | Dynatrace + PD + humans |

---

## 2) Key message (top blue box)

| Bullet | Plain English |
| --- | --- |
| Dynatrace detects and creates/notifies a PagerDuty incident | DT finds the Problem; PD gets an incident / page |
| Humans do triage, notes, coverage, and analytics mostly by hand | After the page, people still do the busywork manually |

So AS-IS is **not** “we have no monitoring.” It is “detection and paging work; response toil does not.”

---

## 3) Box-by-box flow

### Box 1 — Dynatrace

| Text on slide | Meaning |
| --- | --- |
| Problem / Davis AI creates signal | Davis opens a Problem when something breaks |

**Strength:** Detect.  
**Example:** Checkout latency Problem `P-…`.

### Box 2 — PagerDuty

| Text on slide | Meaning |
| --- | --- |
| Incident + escalation pages on-call | PD incident + escalation policy wakes someone |

**Strength:** Page.  
**Example:** Phone rings for “checkout latency high.”

### Box 3 — Human on-call (yellow = hotspot)

| Text on slide | Meaning | Maps to later agents |
| --- | --- | --- |
| Dig docs | Search runbooks / old tickets | → SRE Agent |
| Type notes | Bridge / chat notes by hand | → Scribe Agent |
| Ask coverage | Find who can take the shift | → Shift Agent |
| Export CSV | Pull MTTA/MTTR / noise into spreadsheets | → Insights Agent |

Yellow highlight = **this is the gap** the design wants to shrink.

### Box 4 — Pain

| Pain on slide | What it means |
| --- | --- |
| Slow MTTA/MTTR | Acknowledge/resolve take longer than they should |
| Noise | Too many pages / weak signal |
| Missed notes | Bridge decisions lost; weak PIR |
| Spreadsheet coverage | Fragile on-call tracking outside PD |

Pain is the **result** of Box 3 toil, not a failure of Dynatrace detect or PD page.

---

## 4) Bottom line — “AS-IS gap”

> Dynatrace is strong at detect. PagerDuty is strong at page. The middle toil (triage, bridge notes, coverage, trends) is still mostly human.

| Layer | AS-IS grade |
| --- | --- |
| Detect (Dynatrace) | Strong |
| Page (PagerDuty) | Strong |
| Middle (human) | Weak / high toil |

That sentence is the bridge to TO-BE: insert SRE / Scribe / Shift / Insights **between** page and “done,” without replacing DT or PD.

---

## 5) Same story as your earlier WHY line

| AS-IS slide | Earlier WHY wording |
| --- | --- |
| Dig docs | dig docs |
| Type notes | take notes |
| Ask coverage | fix coverage |
| Export CSV / analytics | report trends |
| Pain | toil consequences (slow MTTR, etc.) |

---

## 6) What this slide is *not* saying

| Not claiming | Reality |
| --- | --- |
| Throw away Dynatrace | Keep detect |
| Throw away PagerDuty | Keep page |
| Humans leave forever | Humans still ack and confirm remediations |
| Agents already live in AS-IS | AS-IS = before / without agents helping |

---

## 7) Mini decision tree

```
Is detect broken?
  → Fix Dynatrace (not this slide’s main point)

Is page broken?
  → Fix PD Service / escalation

Is detect+page OK but response slow / messy?
  → This AS-IS gap → need agents (TO-BE)
```

---

## Data flow map

```
AS-IS:
  Dynatrace ──detect──► PagerDuty ──page──► Human on-call
                                              │
                                              ├ dig docs
                                              ├ type notes
                                              ├ ask coverage
                                              └ export CSV
                                              ▼
                                            Pain
```

## Related files

| Path | Why |
| --- | --- |
| `../3-why-agents-cut-toil-details/` | Same toil → agent map |
| `../4-design-overview-pipeline-details/` | TO-BE-ish pipeline with agents |
| `../2-architecture-design-summary-sheet-explain/` | Summary Sheet |
| `7.sh` | Paths |

## Commands

See `7.sh` in this folder.
