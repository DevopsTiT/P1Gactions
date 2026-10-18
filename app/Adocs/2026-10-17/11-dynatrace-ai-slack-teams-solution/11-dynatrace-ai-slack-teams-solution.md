# Dynatrace AI Slack Teams Solution

## Decision tree

```
Goal: AI help in chat without waiting on PagerDuty Advance Slack
 1) Dynatrace detects Davis problem
 2) Generative AI writes summary + next steps
 3) Post to Slack AND Teams (same text)
 4) If still Active after 30 min → one PagerDuty incident (page only)
 5) Keep PD for on-call schedule; optional Scribe/Shift later
 Primary chat for live talk: Slack #test-channel (or #pagerduty)
 Teams: mirror for Teams-first people
 Never: two PD escalations for one problem
```

## Short takeaway

| Piece | Choice |
|---|---|
| Brain | Dynatrace generative AI (Assistance / Copilot in Workflows) |
| Chat | Dynatrace → Slack **and** Teams |
| Pager | One PagerDuty test/prod service after 30 minutes still open |
| Not used for AI chat (for now) | PagerDuty Advance Slack/Teams (still Not Connected OK) |
| Out of scope | Scribe meeting transcript, Shift coverage AI |

## Summary

This is the buildable solution for your case. Dynatrace owns detection and AI text. Slack and Teams both get the summary. PagerDuty only pages if the problem is still open after 30 minutes. You do not need PagerDuty AI Slack Connected to ship this.

## Investigation

### Words you need first

| Word | What it means |
|---|---|
| WF-A | Workflow: problem open → AI → Slack + Teams |
| WF-B | Workflow: still open 30m → one PagerDuty trigger |
| Primary chat | Where the team discusses (Slack for your demo) |
| Mirror chat | Teams copy of the same AI text |
| Preview then post | Build PD/SILVA payload, then send if ready |

### What you already have

| Item | State |
|---|---|
| Slack Demo workspace | App present; `#test-channel`, `#pagerduty`, `#all-demo-dynatrace` |
| PagerDuty `axa-life-japan` `/ai` | Agents Enabled; Slack/Teams **Not Connected** |
| Need | AI triage in chat + optional escalate |

---

## Solution architecture

```
                    Davis problem (Active)
                              │
                              ▼
              ┌───────── WF-A (immediate) ─────────┐
              │  Wait for root cause analysis       │
              │  Prompt generative AI               │
              │  → Slack #test-channel (primary)    │
              │  → Teams ops channel (mirror)       │
              └─────────────────────────────────────┘
                              │
                              ▼
              ┌───────── WF-B (30 minutes) ────────┐
              │  Minimum duration = 30m             │
              │  Still Active? (+ not acked if any) │
              │  NO  → stop                         │
              │  YES → AI escalate blurb (optional) │
              │      → preview PD payload           │
              │      → post ONE PagerDuty trigger   │
              │      → Slack+Teams "escalated" note │
              └─────────────────────────────────────┘
                              │
                              ▼
                    PagerDuty pages on-call (one path)
```

---

## Prerequisites (admin checklist)

| # | Who | What |
|---|---|---|
| 1 | Dynatrace admin | Workflows enabled; generative AI / AI Units; Copilot permission |
| 2 | Dynatrace admin | **Slack Connector** connection to your Demo Slack |
| 3 | Dynatrace admin | **Teams** connection (Teams connector / Microsoft 365 app as your tenant uses) |
| 4 | You / DT admin | Invite Dynatrace Slack app into `#test-channel` (private) |
| 5 | You / Teams admin | Create or pick a **test** Teams channel; add the Dynatrace bot/app |
| 6 | PagerDuty admin | **Test** service + routing key; escalation = only you |
| 7 | Secrets | Store PD routing key in Dynatrace secret store / connection — not in chat or git |

PagerDuty `/ai` Slack+Teams Connected is **optional** for this solution.

---

## WF-A — AI triage to Slack + Teams (build first)

### Trigger

| Setting | Value |
|---|---|
| Type | Problem |
| State | Active |
| Wait for root cause analysis | On |
| Filters | Start with severity/category you care about; Tier‑1 tags if you have them |
| Minimum duration | Off (send ASAP) |

### Tasks

| Order | Task | Detail |
|---|---|---|
| 1 | Extract fields | `problem_id`, title, description, severity, problem URL |
| 2 | Prompt generative AI | See prompt below |
| 3 | Slack Send message | Channel: `#test-channel` (or `#pagerduty`) |
| 4 | Teams Send message | Same AI text to test Teams channel |

### Generative AI prompt (task 2)

```
Davis problem {{problem_id}} is Active.
Title: {{title}}
Severity: {{severity}}
Context: {{description}}
Problem URL: {{problem_url}}

Write plain text only:
1) Five-line summary for on-call (what broke, blast radius if known).
2) Top 3 investigation steps.
3) What would confirm recovery.
Do not invent metrics or hosts not present in the context.
```

### Slack / Teams message body (tasks 3–4)

```
[Dynatrace AI] New problem {{problem_id}}
{{title}}
{{problem_url}}

{{ai_summary_text}}
```

### Success test

1. Open a **low-impact test problem** (or use Query past events carefully in a lab).  
2. Within a few minutes: same AI text in Slack **and** Teams.  
3. No PagerDuty page yet (WF-B not fired).

---

## WF-B — 30 minutes still open → one PagerDuty page

### Trigger

| Setting | Value |
|---|---|
| Type | Problem |
| State | Active |
| Minimum duration | **30 minutes** |
| Wait for root cause analysis | On |
| Same filters as WF-A | So you do not escalate noise |

### Tasks

| Order | Task | Detail |
|---|---|---|
| 1 | Condition | Still Active (and not acknowledged if field exists) |
| 2 | Optional AI | Short escalate reason |
| 3 | Preview PD | Build Events API v2 trigger JSON (no send) |
| 4 | Post PD | Send trigger **once** with test routing key |
| 5 | Slack + Teams | “Escalated to PagerDuty after 30m still open” + PD incident link if returned |

### PagerDuty payload shape (placeholder)

```json
{
  "routing_key": "{{PD_ROUTING_KEY_SECRET}}",
  "event_action": "trigger",
  "dedup_key": "dynatrace-{{problem_id}}",
  "payload": {
    "summary": "[DT 30m] {{title}}",
    "severity": "error",
    "source": "dynatrace",
    "custom_details": {
      "problem_id": "{{problem_id}}",
      "problem_url": "{{problem_url}}",
      "ai_summary": "{{ai_summary_text}}"
    }
  }
}
```

Use `dedup_key` = problem id so retries do not open duplicate PD incidents.

### Success test

1. Test problem stays Active **31+** minutes.  
2. Exactly **one** PD incident.  
3. Slack and Teams get escalate note.  
4. Problem that closes at 10 minutes → **no** PD incident.

---

## Operating rules

| Rule | Why |
|---|---|
| Slack = primary talk | You already live in `#test-channel` / `#pagerduty` |
| Teams = mirror | Teams-first people see the same AI text |
| One PD service / one escalation | No double-page |
| Fact-check AI | Generative text can be wrong |
| Test keys only until proven | Protect prod on-call |
| Optional later | Connect PD Advance Slack+Teams for Paige/Scribe; not required for WF-A/B |

---

## Ask Dynatrace AI Assistant (copy-paste)

```
Build two Dynatrace Workflows for me:

WF-A: On Davis Problem Active (Wait for root cause analysis ON),
run Prompt generative AI to produce a plain-text summary and top 3 steps,
then send the same message to Slack channel #test-channel AND a Teams test channel
via Dynatrace connectors.

WF-B: On Davis Problem Active with Minimum duration 30 minutes,
if still Active, preview then post ONE PagerDuty Events API v2 trigger
using dedup_key dynatrace-{{problem_id}}, then notify Slack and Teams that we escalated.

Do not create two PagerDuty incidents. Use placeholders for routing keys.
List exact trigger settings and task order.
```

---

## Rollout order

| Step | Action | Done when |
|---|---|---|
| 1 | Admin: Slack + Teams connectors | Test message from a dummy workflow arrives |
| 2 | Build WF-A | AI text in Slack and Teams on test problem |
| 3 | Build WF-B with **test** PD key | One PD incident after 30m |
| 4 | Document primary chat = Slack | Team agrees |
| 5 | Tighten filters (severity/MZ/tags) | Noise acceptable |
| 6 | Optional: PD `/ai` Slack+Teams Connected | Paige/Scribe later if wanted |

## Result

| Goal | Solution |
|---|---|
| Replace Paige-like triage in chat | WF-A Dynatrace AI → Slack + Teams |
| Replace “page if ignored 30m” | WF-B → one PagerDuty trigger |
| Add Teams along Slack | Same AI text, dual notify |
| PD Advance Not Connected | Still OK — not required for this path |
| Keep for later | Scribe, Shift, PD Slack AI |

## Data flow map

```
Problem open
  → WF-A: AI summary → Slack (primary) + Teams (mirror)

Problem still Active @ 30m
  → WF-B: still open? → one PD page → Slack+Teams escalate note

PagerDuty Advance chat AI
  → optional later (admin connect); not on critical path
```

## Related files

| File | Purpose |
|---|---|
| `11-dynatrace-ai-slack-teams-solution.md` | This end-to-end solution |
| `0-pic.md` | Picture flow |
| `1-investigation.md` | Inputs from earlier seqs |
| `2-result.md` | Rollout checklist |
| `3-glossary.md` | Terms |
| `11.sh` | Git one-liners (not run) |
| Seq 7 | PD Slack Not Connected |
| Seq 8 | 30m no-ack idea |
| Seq 9 | Replace PD AI mapping |
| Seq 10 | Teams along Slack OK |

## Commands

No live Dynatrace/PagerDuty/Slack commands are run here. After connectors exist, validate with **test** channels and a **test** PD routing key only.

See `11.sh` for git only. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/11-dynatrace-ai-slack-teams-solution
git commit -m "dynatrace ai slack teams end-to-end solution"
git push
```
