# Solution Context To Be Explain

```
TO-BE
  Dynatrace → PagerDuty → Advance Agents → Human decides
Same detect/page path; agents assist; humans own blast radius
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What this slide is | **TO-BE** target state after adding four PagerDuty Advance agents |
| What stays the same | Dynatrace detects → PagerDuty pages |
| What changes | Agents sit **before** final human decision and cut middle toil |
| Hard rule | Agents suggest/assist; **humans own blast radius** and confirm remediation |

## Summary

Compared with AS-IS (human does all middle work alone), TO-BE keeps DT→PD, inserts SRE / Scribe / Shift / Insights as helpers, then ends on **Human decides**. Red box = new layer. Cost chips on the slide match the Summary Sheet (SRE 4 Actions/ask, Scribe timed usage, Shift/Insights 0).

---

## Investigation

User shared Solution Context — TO-BE slide and asked to explain it (counterpart to AS-IS seq 7).

## Result

Explain key message, main flow boxes, four agent cards, and AS-IS vs TO-BE contrast.

---

## 1) What “TO-BE” means

| Term | What it means | Why you care |
| --- | --- | --- |
| TO-BE | Desired future operating model | Design target after AS-IS pain |
| Same spine | Still Dynatrace → PagerDuty | You do not rip out detect/page |
| New middle | Advance Agents | Shrink dig docs / notes / coverage / trends toil |

---

## 2) Key message (top blue box)

| Bullet | Plain English |
| --- | --- |
| Same Dynatrace → PagerDuty path + four Advance agents beside the human | Keep current integration; add assist layer |
| Agents suggest and assist; humans still own blast radius | AI proposes; people accept risk and scope of impact |

**Blast radius** = how wide the outage / change can hurt. Owning it means you decide rollback, who to call, how far to go — not the bot.

---

## 3) Main flow (four boxes)

### Dynatrace

| Slide text | Meaning |
| --- | --- |
| Problem URL in PD payload | PD incident carries a link back to the Dynatrace Problem |

So responders (and SRE Agent context) can open the Problem card fast.

### PagerDuty

| Slide text | Meaning |
| --- | --- |
| Service + optional Event Orchestration | Incident lands on a Service; EO may route/suppress first |

Same as Design overview stage B.

### Advance Agents (red = new)

| Agents | Role on the flow |
| --- | --- |
| SRE, Scribe, Shift, Insights | Assist layer after page, before final human commit |

This replaces the yellow “Human on-call does everything by hand” hotspot from AS-IS — humans remain, but with help.

### Human decides

| Slide text | Meaning |
| --- | --- |
| Confirm remediation | Approve rollback/restart/etc. |
| Own the page | Ack, drive response, resolve when done |

Matches Summary Sheet safety: human confirms remediations.

---

## 4) Four agent cards (bottom)

| Agent | Slide job | Cost on slide | Cuts which AS-IS toil |
| --- | --- | --- | --- |
| SRE | Triage + runbook | 4 Actions / ask | Dig docs |
| Scribe | Meeting transcript | ~6 / 30m + 2 summary | Type notes |
| Shift | Coverage / override | 0 Actions | Ask coverage |
| Insights | MTTR Q&A + tips | 0 Actions | Export CSV / trends |

| Cost note | Meaning |
| --- | --- |
| Actions | PagerDuty AI usage units for some features |
| 0 Actions | On this sheet, Shift/Insights called out as not consuming Actions the same way |

---

## 5) AS-IS vs TO-BE (side by side)

| Stage | AS-IS | TO-BE |
| --- | --- | --- |
| Dynatrace | Detect | Detect (+ Problem URL in PD) |
| PagerDuty | Page | Page (+ optional EO) |
| Middle | Human alone (yellow) | **Advance Agents** (red) then human |
| End | Pain | **Human decides** (still in control) |
| Outcome focus | Slow MTTR, missed notes, spreadsheets | Faster assist; human-owned remediation |

```
AS-IS:  DT → PD → Human toil → Pain
TO-BE:  DT → PD → Agents assist → Human decides
```

---

## 6) Fake mini story on TO-BE

| Step | What happens |
| --- | --- |
| 1 | Dynatrace Problem; URL lands in PD payload |
| 2 | PD Service pages you |
| 3 | SRE Agent: likely cause + runbook |
| 4 | Scribe: bridge notes if you open a call |
| 5 | You confirm rollback (human decides) |
| 6 | Later: Shift for OOO; Insights for MTTR question |

---

## 7) What TO-BE is *not*

| Not | Reality |
| --- | --- |
| Agents auto-remediate prod | Human confirms |
| Remove Dynatrace or PD | Same path kept |
| Skip Ack | Human still owns the page |
| Replace ServiceNow ticket path | Separate; not on this slide |

---

## Data flow map

```
Dynatrace (Problem URL → PD)
  → PagerDuty (Service ± EO) → page
  → Advance Agents: SRE | Scribe | Shift | Insights
  → Human decides: confirm remediation, own the page
```

## Related files

| Path | Why |
| --- | --- |
| `../7-solution-context-as-is-explain/` | AS-IS counterpart |
| `../4-design-overview-pipeline-details/` | Same pipeline detail |
| `../6-prerequisite-gate-advance-teams-agents/` | Advance gate before TO-BE works |
| `8.sh` | Paths |

## Commands

See `8.sh` in this folder.
