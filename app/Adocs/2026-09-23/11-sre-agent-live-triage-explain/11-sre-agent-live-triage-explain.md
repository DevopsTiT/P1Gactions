# SRE Agent Live Triage Explain

```
Active fire / need triage?
  → Use SRE Agent (this slide)
Need bridge notes? → Scribe (not this slide)
Need coverage? → Shift
Need trends? → Insights

Before any ask:
  Advance On? → Teams/Slack mapped? → TEST Service only?
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What this slide is | Deep dive on **SRE Agent — Live Triage** (first of the four) |
| Job | Helps you in the first minutes after a page: context, runbook, next steps |
| Cost | **4 AI Actions** per ask / nudge / virtual-responder trigger |
| Human rule | Agent **suggests**; you must **confirm** remediations |
| Safe demo | Test Service only (e.g. Checkout latency on `poc-pd-ai-agents-test`) |

## Summary

The SRE Agent is a **virtual responder**. It reads the PagerDuty incident (including about the first 2,000 characters of `custom_details`), optional runbooks, and optional connectors. It answers in Teams, the PD web SRE tab, Ops Console, or as a workflow nudge. It does not replace on-call judgment. Memory can improve after you **Resolve**.

## Investigation

User shared Slide **“1) SRE Agent — Live Triage”** from the Four Agents whole pack. Mapped Key Message, surfaces table, POC story, and limits into beginner SRE language. Tied to Dynatrace ingress (`problem_url` in `custom_details`) from earlier slides.

## Result

Read sections below before a POC afternoon. Prefer Teams `@pagerduty` asks on a test Service. Never paste customer PII into the channel question.

---

## 1) What the SRE Agent is (plain English)

| Idea | What it means | Why you care |
| --- | --- | --- |
| Live triage | Help while the incident is open and loud | Cuts “dig Confluence / guess root cause” time |
| Virtual responder | AI helper next to the human on-call | Speeds MTTA/MTTR without auto-breaking prod |
| Suggest, not decide | Remediations need your confirm | You own blast radius |
| Memory on Resolve | Learnings can stick for that Service | Later asks can feel more specific |

**Analogy:** Like a junior SRE who read the ticket, the runbook, and recent tickets — then proposes a plan. You still approve the change.

---

## 2) Key Message box (top of slide)

| Claim on slide | Plain English |
| --- | --- |
| Reads incident + ~2k chars `custom_details` | Only the start of custom fields is analyzed — put the **Dynatrace problem URL** and important tags early |
| + runbook + optional connectors | Upload a small runbook; optionally wire Grafana/Datadog/CloudWatch/Confluence/GitHub |
| Suggests next steps | Lists likely causes / first checks |
| Human must confirm remediations | No silent “restart prod” without you |
| Memory saves on Resolve | Closing the incident can store useful context for next time |

**Dynatrace tip (from glance slide):** Dynatrace usually **creates** the incident. It is often **not** the main item on the SRE connector list. Enrich connectors as needed; keep `problem_url` in `custom_details`.

---

## 3) Surfaces table (where you use it)

| Surface | How to start | Good first ask | Beginner note |
| --- | --- | --- | --- |
| MS Teams (Early Access) | `@pagerduty …` in a **mapped** channel | What are some likely root causes? | Most common POC path for Teams-only orgs |
| Incident SRE tab | PD web → open incident → SRE Agent | Analyze past incidents | Works even if chat is flaky |
| Ops Console | AIOps + Advance → SRE tab | What steps should I take first? | Needs AIOps + Advance entitlement |
| Virtual responder | Incident Workflow / Escalation (EA) | Same job; still **4 Actions** per trigger | Auto-nudge when page fires — still costs Actions |

**Mapped channel** = the Teams channel linked to your test PagerDuty Service so the incident card appears there.

---

## 4) POC story (bottom of slide)

Walk-through the slide’s example:

```
Dynatrace-shaped test incident
  title: "Checkout latency high"
  Service: test only (e.g. poc-pd-ai-agents-test)
        │
        ▼
Teams channel shows incident card
        │
        ▼
@pagerduty What are some likely root causes?
        │
        ▼
Upload / attach runbook: poc-checkout-latency.md
        │
        ▼
@pagerduty Analyze past incidents
@pagerduty What steps should I take first?
        │
        ▼
If remediation suggested → READ it → approve or decline
        │
        ▼
Resolve test incident → memory can save learnings
```

| Step | Why it is in the story |
| --- | --- |
| Test Service | Avoids paging the real rotation |
| Upload runbook | Grounds answers in **your** steps, not generic advice |
| Past incidents | Uses history on that Service |
| Read remediation | AI can be wrong; verify in Dynatrace / deploy tools |
| Resolve | Triggers memory save path |

---

## 5) Limits (do not skip)

| Limit | What it means | Why you care |
| --- | --- | --- |
| Runbook ≤ **100 KB** | Keep `.md` / `.txt` small and clear | Oversized files may not load |
| **25 files** / conversation | Cap on uploads in one chat | Prefer one good runbook over many scraps |
| No customer **PII** in channel questions | Channel members can see Q&A | Privacy + compliance |
| ~**2,000** chars of `custom_details` | Front-load important fields | Put problem URL first |

---

## 6) Cost

| Action | AI Actions |
| --- | --- |
| Each Teams / chat ask | **4** |
| Each nudge / virtual responder trigger | **4** (same cost model on this deck) |

Shift and Insights are 0 on this pack. SRE and Scribe spend budget.

---

## 7) Common mistakes

| Mistake | Better approach |
| --- | --- |
| Demo on prod Service | Use `poc-pd-ai-agents-test` (or equivalent) |
| Expect Dynatrace alone as “connector” | DT is ingress; add log/runbook connectors if needed |
| Paste secrets / customer PII into `@pagerduty` asks | Ask about symptoms and service names only |
| Auto-approve remediations | Always read and confirm |
| Skip Resolve | You miss the memory save path |

---

## Data flow map

```
Dynatrace Problem
  (+ problem_url early in custom_details)
        │
        ▼
PagerDuty Incident (test Service)
        │
        ├── page → you
        └── SRE Agent reads:
              incident fields
              ~2k chars custom_details
              runbook (≤100 KB)
              optional connectors
        │
        ▼
Teams / SRE tab / Ops Console / Workflow nudge
        │
        ▼
You confirm or decline remediation
        │
        ▼
Resolve → optional service memory
```

---

## Related files

| File | Role |
| --- | --- |
| Whole pack PPT Slide 10 | Source slide |
| `Daily Files/2026-09-23/10-four-agents-ppt-each-page-explain/` | Full 42-page guide |
| `Daily Files/2026-09-23/9-four-agents-at-a-glance-explain/` | Four-agent comparison |
| `11.sh` | Optional open helpers (user runs) |

## Commands

See `11.sh`. Type Teams asks yourself; do not point prod routing keys at POC.
