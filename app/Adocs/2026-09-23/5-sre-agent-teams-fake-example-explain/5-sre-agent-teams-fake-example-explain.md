# Sre Agent Teams Fake Example Explain

```
PD page “checkout latency high”
  → Teams: @PagerDuty What are likely root causes?
  → SRE Agent: recent deploy + runbook link
  → Human decides rollback
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What this shows | How **SRE Agent** cuts “dig docs” toil after a page |
| Where | Microsoft **Teams** + PagerDuty Advance |
| Human still decides | Agent suggests; person chooses rollback |

## Summary

This fake story is one pass through the pipeline after the page: wake up → ask SRE Agent in Teams → get deploy + runbook context → you approve the fix. It is triage help, not auto-remediation.

---

## Investigation

User asked to explain the fake SRE Agent Teams example used in the “dig docs → SRE Agent” toil write-up.

## Result

Walk the example beat-by-beat: triggers, chat ask, agent answer, human decision, safety.

---

## 1) The example in one line

Someone gets a PagerDuty page titled **“checkout latency high”**. In Teams they ask **`@PagerDuty What are likely root causes?`**. The **SRE Agent** answers with something like “recent deploy” plus a **runbook link**. The human then **decides to rollback**.

---

## 2) Beat-by-beat

### Beat 1 — PD page “checkout latency high”

| What happened before | Meaning |
| --- | --- |
| Dynatrace (or similar) saw slow checkout | Detection |
| Event hit a PD Service | Incident created |
| Escalation fired | Your phone/Teams/PD app notified you |

| Field | Fake value |
| --- | --- |
| Incident title / summary | checkout latency high |
| Your action first | **Acknowledge** (own it; stop escalation) |

This is stage **“page on-call”**. The agent has not helped yet.

### Beat 2 — In Teams `@PagerDuty What are likely root causes?`

| Piece | What it means |
| --- | --- |
| Teams | Chat where the PD bot / Advance agents are connected |
| `@PagerDuty` | Mention the PagerDuty bot so the ask is routed |
| Question | Natural-language triage ask — “what might be wrong?” |

| Why this cuts toil | Instead of manually searching Confluence and old tickets under stress |
| --- | --- |
| What you need set up | Advance + SRE Agent on + Teams linked + `linkUser` done |

You usually ask from a **channel mapped to that Service/incident**, or from a flow where the bot knows which incident you mean (product UX varies; POC uses the incident-linked channel).

### Beat 3 — Agent cites recent deploy + runbook link

| Agent output (fake) | Why it helps |
| --- | --- |
| Recent deploy called out | Points at change-risk (common latency cause) |
| Runbook link | Skips “which doc?” hunting |

| What the agent is doing | **SRE triage** — context + likely causes + docs |
| --- | --- |
| What it is not doing | Automatically rolling back production |

This matches “dig docs → SRE Agent” on the WHY slide.

### Beat 4 — Human decides rollback

| Who | Action |
| --- | --- |
| Human | Judges: deploy looks guilty + runbook says rollback → **do** rollback |
| Human | Confirms remediation (Summary Sheet safety rule) |
| Later | Fix works → resolve PD (+ Dynatrace Problem close / SNOW resolve if wired) |

**Decide** is the important word: agent **suggests**, human **owns** the risk.

---

## 3) Where this sits on the big pipeline

```
Dynatrace Problem (e.g. checkout slow)
  → PD Service
  → page “checkout latency high”     ← Beat 1
  → SRE triage in Teams              ← Beats 2–3
  → Human rollback                   ← Beat 4
```

Scribe / Shift / Insights are **not** in this particular fake example.

---

## 4) What you would type / click (POC style)

| Step | You do |
| --- | --- |
| 1 | Ack the PD incident |
| 2 | Open the linked Teams channel (or incident SRE Agent panel) |
| 3 | Type: `@PagerDuty What are likely root causes?` |
| 4 | Read answer: deploy mention + runbook URL |
| 5 | Open runbook; confirm steps |
| 6 | If agreed: rollback with app owner |
| 7 | Verify latency recovered; Resolve incident |

Optional follow-ups (same agent):

| Ask | Why |
| --- | --- |
| `@PagerDuty What steps should I take first?` | Ordered next actions |
| Upload / attach runbook earlier | Better citations next time |
| `@PagerDuty Analyze past incidents` | Similar history |

(Exact slash-commands vary by PD/Teams version; the idea is NL Q&A for triage.)

---

## 5) Fake data pack for this story

| Item | Fake value |
| --- | --- |
| Page title | checkout latency high |
| Likely service | EIP Checkout |
| Agent hint | Deploy `checkout-api 1.8.4` correlated with spike |
| Runbook | `https://confluence.example/runbooks/eip` |
| Human decision | Rollback to `1.8.3` |
| Cost note | ~4 AI Actions for that ask (per Summary Sheet) |

---

## 6) Good vs bad outcomes

| Good | Bad |
| --- | --- |
| Fast hypothesis + doc link | Agent ignored; 20 min Confluence search |
| Human confirms then rolls back | Blind trust → wrong change with no confirm |
| Test Service in POC | Same demo on prod schedule pages everyone |

---

## 7) How this differs from “bot auto-fixes”

| Pattern | This example |
| --- | --- |
| Auto-remediate | **No** |
| Suggest + human decide | **Yes** |
| Matches slide safety | Human confirms remediations |

---

## Data flow map

```
Page: “checkout latency high”
  → Human Ack
  → Teams @PagerDuty “likely root causes?”
  → SRE Agent: deploy + runbook
  → Human: rollback (confirm)
  → Verify → Resolve
```

## Related files

| Path | Why |
| --- | --- |
| `../3-why-agents-cut-toil-details/` | Parent toil → agent map |
| `../4-design-overview-pipeline-details/` | Full pipeline |
| `Daily Files/2026-08-25/9-pagerduty-four-agents-poc-examples/` | SRE POC steps |
| `5.sh` | Paths |

## Commands

See `5.sh` in this folder.
