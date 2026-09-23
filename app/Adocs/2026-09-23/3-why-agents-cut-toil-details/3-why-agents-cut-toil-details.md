# Why Agents Cut Toil Details

```
Dynatrace finds the Problem
  │
  └─ Humans still do toil:
        dig docs → SRE Agent
        take notes → Scribe Agent
        fix coverage → Shift Agent
        report trends → Insights Agent
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What DT already solves | Detect and open a **Problem** (something is wrong) |
| What DT does not do alone | Read runbooks for you, scribe the bridge, fix who is on-call, write weekly trend reports |
| What “toil” means here | Repeat manual work after the page that burns on-call time |
| How agents help | Four Advance agents each attack one of those four toils |

## Summary

The slide line means: monitoring is solved; **response busywork** is not. Dynatrace wakes the system with a Problem → PD pages a human. That human still spends time on docs, notes, coverage, and trends. SRE / Scribe / Shift / Insights are meant to shrink those four jobs — with a human still confirming remediations.

---

## Investigation

User asked for details on the Background WHY sentence from the Architecture Design Summary Sheet.

## Result

Break the sentence into: (1) what Dynatrace does, (2) four human toils with examples, (3) which agent cuts each, (4) what stays human.

---

## 1) First half — “Dynatrace finds the problem”

| Idea | What it means | Example |
| --- | --- | --- |
| Find | Davis detects failure rate / latency / availability issues | Checkout error rate spikes |
| Problem | Grouped incident object in Dynatrace | `P-240917001` |
| Hand-off | Workflow/notification can open PD (and SNOW) | Page + ticket |

**Plain English:** Dynatrace is good at **detection**. The WHY line assumes that part already works.

What this half does **not** claim:

| Not claimed | Reality |
| --- | --- |
| DT writes your postmortem | Still human / Insights / Scribe help |
| DT replaces on-call | PD still pages a person |
| DT auto-fixes production | Safety rule: human confirms remediations |

---

## 2) What “toil” means here

| Term | What it means | Why you care |
| --- | --- | --- |
| Toil | Manual, repetitive, predictable ops work | Steals time from real fixing |
| After the page | Work that happens once someone is already awake | MTTA may be fine; MTTR still slow because of busywork |
| Cut toil | Agents draft / suggest / summarize so humans decide faster | Not “bots ship to prod alone” |

---

## 3) Four human jobs the sentence lists

### A) Dig docs

| What humans do today | Pain |
| --- | --- |
| Search Confluence / Notion / old tickets | Slow under stress |
| Guess which runbook matches this failure | Wrong runbook wastes time |
| Ask “did we see this last month?” in chat | Tribal knowledge |

| Agent that cuts it | How |
| --- | --- |
| **SRE Agent** | Triage: pull context, suggest likely causes, surface runbooks, summarize similar past incidents |

**Fake example:** PD page “checkout latency high” → in Teams `@PagerDuty What are likely root causes?` → agent cites recent deploy + runbook link → human decides rollback.

### B) Take notes

| What humans do today | Pain |
| --- | --- |
| Type in Zoom/Teams while also debugging | Miss decisions |
| Rebuild timeline for PIR next day | Incomplete / biased memory |
| Copy-paste chat into the INC | Noisy, late |

| Agent that cuts it | How |
| --- | --- |
| **Scribe Agent** | Joins the bridge, transcribes, drafts meeting summary / actions |

**Fake example:** P1 bridge 15 minutes → Scribe on the call → after hangup you get decisions + action list for PIR / SNOW notes.

### C) Fix coverage

| What humans do today | Pain |
| --- | --- |
| Someone is OOO Friday; schedule conflicts | Gaps or double-pages |
| Manually find a substitute | Slack ping storm |
| Write schedule overrides by hand | Errors, late updates |

| Agent that cuts it | How |
| --- | --- |
| **Shift Agent** | Flags conflicts, helps request coverage, draft overrides (Slack-first DMs) |

**Fake example:** Shift warns “Alice OOO overlaps primary” → request coverage → Bob accepts → override written.

### D) Report trends

| What humans do today | Pain |
| --- | --- |
| Pull MTTA/MTTR in spreadsheets | Weekly chore |
| Argue which team is noisiest | No shared data view |
| Forget to tune noisy services | Same pages forever |

| Agent that cuts it | How |
| --- | --- |
| **Insights Agent** | Answer trend questions; maturity / noise tips; optional weekly nudges |

**Fake example:** “How did Payments MTTR change last 6 months?” → Insights answers from PD data → suggest Dynamic Notifications / quieter routing.

---

## 4) Map sentence → agents (one table)

| Phrase in the slide | Human toil | Agent |
| --- | --- | --- |
| dig docs | Find runbooks / similar incidents | **SRE** |
| take notes | Bridge / PIR notes | **Scribe** |
| fix coverage | Who is on-call when someone is out | **Shift** |
| report trends | MTTA/MTTR / noise / maturity | **Insights** |
| Dynatrace finds the problem | Detection | *(Dynatrace — not an agent)* |
| Agents cut that toil | Assist after page | All four |

---

## 5) End-to-end story (all four toils)

```
02:15  Dynatrace opens Problem (FIND — done)
02:15  PD pages you
02:16  You ack
02:17  Dig docs     → ask SRE Agent (runbook + likely cause)
02:25  Bridge call  → Scribe takes notes
02:40  Fix applied; Problem closes
Next week
  Coverage gap Fri → Shift helps find backup
  Manager asks MTTR → Insights answers
```

Without agents: same detection, but 02:17–02:40 and next week are heavier manual work.

---

## 6) What agents do *not* replace

| Still human | Why |
| --- | --- |
| Ack the page | Ownership |
| Decide rollback / change | Safety — slide says human confirms remediations |
| Official SNOW ticket process | Your Connector path; agents don’t replace ITSM |
| Approve production risk | Never “agent auto-remediate prod” in this design |

---

## 7) Cost / chat footnotes (from the same sheet)

| Agent | Typical cost note | Chat note |
| --- | --- | --- |
| SRE | 4 AI Actions / ask | Teams or Slack |
| Scribe | ~6 / 30 min + 2 summary | Teams or Slack |
| Shift | 0 on sheet | Slack-first for coverage DMs |
| Insights | 0 on sheet | Teams Q&A OK; some nudges Slack-oriented |

---

## Data flow map

```
Dynatrace: FIND Problem
PagerDuty: PAGE human
Human still faces toil:
  docs ──► SRE Agent
  notes ─► Scribe Agent
  coverage ► Shift Agent
  trends ─► Insights Agent
Result: faster assist; human still decides
```

## Related files

| Path | Why |
| --- | --- |
| `../2-architecture-design-summary-sheet-explain/` | Full summary sheet |
| `Daily Files/2026-08-25/8-pagerduty-ai-agents-detailed/` | Per-agent detail |
| `Daily Files/2026-08-25/9-pagerduty-four-agents-poc-examples/` | POC steps |
| `3.sh` | Paths |

## Commands

See `3.sh` in this folder.
