# Prerequisite Gate Advance Teams Agents

```
Prerequisite gate (do in order)
  1) PagerDuty Advance enabled
  2) Connect Teams and/or Slack
  3) Enable the four agents
  4) TEST service only
Without Advance → agent toggles do nothing
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| What this is | Ordered setup checklist before any SRE/Scribe/Shift/Insights POC |
| Hard gate | **PagerDuty Advance** must be on — otherwise agent switches are useless |
| Safe demo | Use a **TEST** Service / schedule only (do not page prod) |

## Summary

You cannot usefully “turn on AI agents” on a basic PagerDuty account. Advance is the license/entitlement. Then connect chat, flip agent toggles, and run everything against a test Service so demos never wake production on-call.

---

## Investigation

User asked to explain the prerequisite gate line from the Four Agents / Summary Sheet materials, including why toggles do nothing without Advance.

## Result

Treat the four steps as a strict sequence. Step 1 failing explains “I enabled agents but nothing works.”

---

## 1) What “prerequisite gate” means

| Idea | What it means | Why you care |
| --- | --- | --- |
| Gate | Must-pass checklist before the POC | Skipping order causes fake “broken agents” |
| Ordered | Later steps depend on earlier ones | Chat without Advance still will not run product agents |
| TEST only | Safety boundary for demos | Matches Summary Sheet safety row |

---

## 2) Step 1 — PagerDuty Advance enabled

| Idea | What it means |
| --- | --- |
| Advance | Paid / entitled PagerDuty tier that includes AI Agents (and related AI features) |
| Who turns it on | Usually account Owner / Global Admin + commercial entitlement |
| Where you see it | AI → AI Settings / Advance features available in the account |

**Without Advance:**

| What you might see | Reality |
| --- | --- |
| UI toggles for agents | Present but inert |
| “Enable SRE Agent” clicked | **Does nothing useful** — no real agent behavior |
| Expectation “bot will triage” | Fails; not a Teams misconfig yet |

That is exactly: **Without Advance, agent toggles do nothing.**

| Check | Pass looks like |
| --- | --- |
| Account has Advance | AI Agents section is real/usable for your org |
| Your team has Advance access | Responders on that team can use agents once enabled |

---

## 3) Step 2 — Connect Teams / Slack

| Idea | What it means |
| --- | --- |
| Connect chat | Link PagerDuty to Microsoft Teams and/or Slack workspace |
| Why needed | Agents are largely used via `@PagerDuty` asks / channel flows |
| User link | Often each person runs something like `linkUser` so PD knows your chat identity |

| Chat | Typical strength on your sheet |
| --- | --- |
| Teams | SRE, Scribe, Insights Q&A |
| Slack | Same + **Shift** coverage DMs (Slack-first) |

| If you skip this | Symptom |
| --- | --- |
| Advance on, agents on, no chat | Nowhere natural to ask; web panels alone may be limited |
| Chat connected, user not linked | Bot may not personalize / may not map you |

---

## 4) Step 3 — Enable agents

| Where | AI → AI Settings → Assistant and AI Agents (wording may vary) |
| --- | --- |
| What you enable | SRE, Scribe, Shift, Insights (the four) |
| Who can flip | Owner / Global Admin (typical) |

| Agent | What enabling unlocks |
| --- | --- |
| SRE | Triage Q&A / runbook help |
| Scribe | Bridge join / transcript / summary |
| Shift | Coverage / conflict help |
| Insights | Trend / maturity Q&A |

**Only meaningful after Advance (step 1).** Toggles here are the “on” switch for product features, not a substitute for license.

---

## 5) Step 4 — TEST service only

| Idea | What it means |
| --- | --- |
| TEST Service | Dedicated PD Service for POC (e.g. `poc-pd-ai-agents-test`) |
| Test schedule | Escalation pages **only you** (or a tiny safe list) |
| Why | Agents + demos must not page production on-call |

| Do | Do not |
| --- | --- |
| Create incidents on test Service | Point Dynatrace prod routing key at test demos carelessly |
| Use test Teams channel | Run first SRE asks on a prod P1 channel |
| Resolve test incidents when done | Leave noisy test pages on real schedules |

This matches Summary Sheet **Safety**: Test Service / test schedule only; human confirms remediations.

---

## 6) Why the order matters (failure map)

| You did | Forgot | What happens |
| --- | --- | --- |
| Flipped agent toggles | Advance | **Toggles do nothing** |
| Advance + agents | Chat connect | Nowhere to `@PagerDuty` usefully |
| All of above | Test Service | Risk of paging prod / polluting real services |
| Chat only | Advance | Bot may exist; **Advance agents still dead** |

```
Advance? ─no─► stop (toggles useless)
   │yes
Connect chat? ─no─► limited / frustrating POC
   │yes
Enable agents? ─no─► features off
   │yes
TEST service? ─no─► unsafe
   │yes
Ready for SRE/Scribe/Shift/Insights demos
```

---

## 7) Who does what (roles)

| Role | Typical job at the gate |
| --- | --- |
| Account Owner / Global Admin | Confirm Advance; enable agents; connect Teams/Slack org-side |
| Microsoft / Slack admin | Approve app / Graph permissions |
| You (POC owner) | Create TEST Service + schedule that only pages you; run asks |
| Responder | `linkUser`; use agents after enable |

API tokens are for **custom** bot POCs — **not** required to flip these product agent toggles.

---

## 8) Mini checklist (copy)

| # | Gate item | Done? |
| --- | --- | --- |
| 1 | PagerDuty Advance enabled for the account/team | |
| 2 | Teams and/or Slack connected; users linked | |
| 3 | SRE / Scribe / Shift / Insights enabled in AI Settings | |
| 4 | TEST Service + test schedule (pages only you) | |
| — | Remember: no Advance ⇒ toggles do nothing | |

---

## Data flow map

```
Commercial: Advance entitlement
  → Admin: connect Teams/Slack
  → Admin: enable 4 agents
  → You: TEST Service only
  → Then: page → @PagerDuty asks → agent answers
```

## Related files

| Path | Why |
| --- | --- |
| `../2-architecture-design-summary-sheet-explain/` | Summary Sheet (safety/cost) |
| `../5-sre-agent-teams-fake-example-explain/` | Example after gate passes |
| `Daily Files/2026-08-25/13-pagerduty-ai-agents-setup-permissions/` | Permissions detail (if present) |
| `6.sh` | Paths |

## Commands

See `6.sh` in this folder.
