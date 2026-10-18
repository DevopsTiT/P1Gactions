# Dynatrace AI Replace PagerDuty AI

## Decision tree

```
Want Dynatrace Assistance AI instead of (some) PagerDuty Advance?
 Which PD AI job?
   Paige / catch-me-up / RCA tips
     → REPLACE with: Problem workflow + Prompt generative AI + Slack/email
   Status update draft
     → REPLACE with: Copilot summary on problem open/update → Slack
   Auto page if open 30m / no ack
     → REPLACE with: Workflow min duration 30m → PagerDuty Events API (keep PD as pager only)
   Insights / “why noisy / MTTR”
     → PARTIAL: Davis Copilot + Notebooks / DQL on Grail
   Scribe (meeting transcript)
     → KEEP PagerDuty (or Zoom notes) — Dynatrace does not replace bridge transcription
   Shift (on-call coverage / OOO)
     → KEEP PagerDuty — Dynatrace has no schedule AI
 Slack PD AI Still Not Connected?
   → Prefer Dynatrace→Slack Connector path now; keep PD only for paging
```

## Short takeaway

| Question | Answer |
|---|---|
| Can Dynatrace AI replace **all** PagerDuty AI? | No. |
| Best replace targets | Triage summary, remediation tips, catch-up text, Slack/email status, 30m escalate. |
| Must keep in PagerDuty | On-call schedules (Shift), meeting scribe, PD incident lifecycle if you still page there. |
| Core pattern | Problem trigger → generative AI summarize → Slack (Dynatrace connector) and/or create PD incident. |
| Your situation | PD Slack AI blocked → Dynatrace Slack path unblocks chat help without waiting on PD Advance Slack. |

## Summary

Use **Dynatrace Intelligence (Davis Copilot / generative AI in Workflows)** to replace the **chat triage and summary** parts of PagerDuty AI. Keep PagerDuty for **who gets paged** and for **Scribe/Shift** if you need those. Wire Dynatrace → Slack directly so responders get AI text even when PagerDuty Advance Slack is Not Connected.

## Investigation

### Words you need first

| Word | What it means | Why you care |
|---|---|---|
| PagerDuty AI / Advance | PD’s agents: Paige, Scribe, Shift, Insights. | What you want to reduce dependence on. |
| Dynatrace Assistance AI | Davis Copilot + generative AI workflow tasks. | Your replacement brain for observability. |
| Problem trigger | Workflow starts on a Davis problem. | Same “incident opened” moment as PD. |
| Slack Connector (Dynatrace) | Dynatrace posts to Slack itself. | Does not need PD Slack AI Connected. |
| Events API | PD API to open/ack/resolve incidents. | Keep PD as the pager, not the AI. |

### Replace vs keep matrix

| PagerDuty AI function | Dynatrace Assistance AI replacement | Verdict |
|---|---|---|
| Paige: summarize incident, likely causes, next steps | Problem → Prompt generative AI → Slack/email | **Replace** |
| Catch me up / wrap me up | Same summary on open + on update; or on-demand Copilot on the problem | **Replace** |
| Proactive insights in channel | Workflow posts AI text to `#test-channel` / `#all-demo-dynatrace` | **Replace** |
| Status update draft | AI task writes plain-text update → Slack / SILVA note | **Replace** |
| Escalate if open too long | Min duration 30m workflow → create PD incident | **Replace AI part**; **keep PD** as pager |
| Insights analytics Q&A | Copilot + Notebooks / DQL | **Partial replace** |
| Scribe meeting transcript | None equivalent in Dynatrace | **Keep PD** (or manual notes) |
| Shift coverage / OOO | None equivalent | **Keep PD** |
| SRE Agent remediations with human confirm | Limited: AI suggests steps; remediations stay human / other automations | **Partial** |

### Target architecture (recommended)

```
                    Dynatrace (source of truth for symptoms)
                              │
              Problem opens / stays open 30m
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
     Prompt generative AI   Slack Connector   PagerDuty Events API
     (summary + next steps) (chat “catch me up”) (page humans only)
              │               │               │
              └───────────────┴───────────────┘
                              │
                    Optional: SILVA preview→post
                              │
         Keep PD Advance only for Scribe / Shift if needed later
```

### Solution pack (four workflows)

#### WF1 — Replace Paige “triage / catch me up” (no PD AI needed)

| Step | Setting |
|---|---|
| Trigger | Problem, Active, Wait for root cause analysis On |
| Task 1 | Extract problem id, title, description, URL |
| Task 2 | **Prompt generative AI** (summary + top 3 actions, plain text) |
| Task 3 | **Slack Send message** via Dynatrace Slack Connector to `#test-channel` or ops channel |
| Task 4 (optional) | Email same text |

**AI prompt (workflow task):**

```
Davis problem {{problem_id}} just became Active.
Title: {{title}}
Context: {{description}}
Write: (1) 5-line plain-text summary for Slack, (2) top 3 investigation steps, (3) what would confirm recovery.
No markdown. Fact-based only from the context given.
```

#### WF2 — Replace “still broken, escalate” (PD as pager only)

| Step | Setting |
|---|---|
| Trigger | Problem Active, **Minimum duration = 30 minutes** |
| Condition | Still Active (+ not acked if available) |
| Task 1 | Optional: generative AI escalate blurb |
| Task 2 | Preview PagerDuty payload |
| Task 3 | Post PagerDuty **trigger** (test routing key first) |
| Task 4 | Optional: Slack “escalated to PD after 30m” |

This replaces waiting for Paige to notice. PagerDuty only pages; Dynatrace AI wrote the context.

#### WF3 — Replace status-update draft

| Step | Setting |
|---|---|
| Trigger | Problem update, or manual/workflow button |
| Task | Generative AI: stakeholder update (impact, status, next check time) |
| Deliver | Slack + optional SILVA work note (preview then post) |

#### WF4 — Partial Insights replacement

| Need | Dynatrace approach |
|---|---|
| “What failed most this week?” | Notebook + DQL on problems/logs; ask Copilot to explain the table |
| “Is error rate up?” | Dashboard SLI panels + Copilot Q&A |
| Weekly maturity nudges | Not a full Insights Agent clone — schedule a weekly workflow email if needed |

### How to use Dynatrace AI Assistant to build this

Paste into Davis Copilot / AI Assistant:

```
Design Dynatrace Workflows that replace these PagerDuty AI features:
1) Paige triage: on problem open, generative AI summary + next steps to Slack (Dynatrace Slack Connector).
2) 30-minute still Active: create PagerDuty incident via Events API (preview then post), include AI summary in the body.
3) Status update draft to Slack for stakeholders.
Do NOT try to replace Scribe (meeting transcript) or Shift (on-call schedule).
List triggers, tasks, sample prompts, and placeholders for secrets.
Filter: only severity/category suitable for Tier-1; Wait for root cause analysis enabled.
```

### License and permissions (check with admin)

| Need | Why |
|---|---|
| AI Units / Dynatrace Intelligence generative AI | Prompt generative AI tasks |
| `davis-copilot:conversations:execute` (or current Copilot permission) | Copilot / generative steps |
| Workflows + Slack Connector connection | Post to Slack without PD Advance |
| PagerDuty routing key in secret store | Escalate workflow only |
| Problem trigger permission `storage:events:read` | Read Davis problems |

### What you stop doing vs keep

| Stop depending on PD AI for | Keep PagerDuty for |
|---|---|
| Channel triage text | Escalation policies / who is on call |
| Catch-me-up summaries | Optional Scribe bridges |
| AI-written status blurbs | Optional Shift coverage |
| Deciding when to page (30m rule in DT) | Receiving the page (mobile/PD) |

## Result

| Priority | Build first |
|---|---|
| P0 | WF1: Problem → AI summary → Dynatrace Slack (unblocks you while PD Slack AI is Not Connected) |
| P1 | WF2: 30m still open → PagerDuty trigger with AI body |
| P2 | WF3: status update draft |
| P3 | Notebooks + Copilot for Insights-like questions |
| Never claim replaced | Scribe, Shift |

## Data flow map

```
PagerDuty AI (today, blocked on Slack)
  Paige / catch-up / insights-in-Slack ──X── Not Connected

Dynatrace Assistance AI (replacement path)
  Davis problem
    → Prompt generative AI
    → Slack Connector  →  #test-channel / ops channel
    → (30m) Events API → PagerDuty page only
    → (optional) SILVA preview→post

Keep in PagerDuty: schedules, optional Scribe
```

## Related files

| File | Purpose |
|---|---|
| `9-dynatrace-ai-replace-pagerduty-ai.md` | This solution |
| `0-pic.md` | Replace vs keep |
| `1-investigation.md` | Mapping notes |
| `2-result.md` | Build order |
| `3-glossary.md` | Terms |
| `9.sh` | Git one-liners (not run) |
| 2026-10-17 seq 7 | PD Slack Not Connected |
| 2026-10-17 seq 8 | 30m no-ack incident idea |
| 2026-08-25 seq 9–10 | PD four agents background |
| Dynatrace docs | Generative AI in workflows, Slack problem notifications |

## Commands

No live API calls in this answer. In Dynatrace UI: create WF1 first, test with a low-impact problem, post to a **test** Slack channel.

See `9.sh` for git only. None have been run.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-17/9-dynatrace-ai-replace-pagerduty-ai
git commit -m "dynatrace ai replace pagerduty ai partial"
git push
```
