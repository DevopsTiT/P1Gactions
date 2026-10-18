# Event Path Dynatrace AI Replace PD

## Decision tree

```
Davis problem / event opens
  Need “catch me up” / triage like Paige?
    → Dynatrace AI Assistant (UI) OR WF-A generative AI → Slack/Teams
  Need auto status text in chat?
    → WF-A posts AI summary (Dynatrace Slack/Teams connectors)
  Still open after 30 min, nobody handled it?
    → WF-B → ONE PagerDuty page (PD = pager only, not PD AI)
  Need meeting transcript / on-call coverage AI?
    → Keep PagerDuty Scribe / Shift (Dynatrace cannot replace)
  PagerDuty /ai Slack = Not Connected?
    → This Dynatrace path still works (does not need PD Advance chat)
```

## Short takeaway

| When the event happens | Who does the AI job | What replaces PagerDuty AI |
|---|---|---|
| Problem just opened | Dynatrace (WF-A + Assistant) | Paige “catch me up / RCA tips” |
| You open the problem in Dynatrace | Davis Copilot / AI Assistant | Interactive `@PagerDuty` Q&A |
| Chat needs a summary | Dynatrace → Slack and/or Teams | PD Advance chat Connected |
| Still Active after 30 minutes | Dynatrace WF-B → PD Events API | Paige “escalate / notice” |
| Bridge / schedule help | Still PagerDuty | Nothing in Dynatrace |

## Summary

When a Dynatrace problem opens, **Dynatrace AI Assistant** does the triage and chat-summary work that PagerDuty Paige normally does. Dynatrace posts that text to Slack and/or Teams. If the problem is still open after 30 minutes, Dynatrace creates **one** PagerDuty incident so humans get paged. PagerDuty stays the pager and schedule tool; you do not need PagerDuty AI Connected in Slack for this path.

## Investigation

### What this is (plain English)

An **event** here means a **Davis problem** in Dynatrace: something broken or degraded (error spike, service down, and so on).

**PagerDuty AI** (Advance) helpers like **Paige** summarize incidents in Slack/Teams. If that chat AI is blocked, you still need help when the event fires.

**Dynatrace AI Assistant** (Davis Copilot + generative AI in Workflows) reads the same problem and writes a plain-language summary and next steps. That replaces the *chat triage* part of PagerDuty AI. PagerDuty can still **page** people later.

### Function map (replace vs keep)

| PagerDuty AI function | What it means | Dynatrace replace when event happens | Verdict |
|---|---|---|---|
| Paige triage / catch me up | Short summary + likely causes + next steps | WF-A Prompt generative AI → Slack/Teams; or ask Assistant on the problem | **Replace** |
| Ask questions in chat | `@PagerDuty What are likely root causes?` | Open problem → AI Assistant in Dynatrace UI | **Replace** (place changes: Dynatrace UI, not PD bot) |
| Proactive channel update | Bot posts insights when incident starts | WF-A auto-posts to Slack/Teams | **Replace** |
| Status update draft | Stakeholder-ready text | Same AI task or optional status prompt | **Replace** |
| Escalate if ignored | Someone notices the ticket is old | WF-B **Minimum duration 30m** → PD trigger | **Replace AI notice**; **keep PD** as pager |
| Insights analytics | “Why noisy / MTTR?” | Copilot + Notebooks / DQL (after the event) | **Partial** |
| Scribe | Meeting transcript | None | **Keep PD** |
| Shift | Who is on-call / coverage | None | **Keep PD** |

### Timeline when the event happens

| Time | What happens | Dynatrace AI role | PagerDuty role |
|---|---|---|---|
| T+0 | Davis problem becomes Active | WF-A runs after root-cause wait; AI writes summary; posts to Slack and/or Teams | No page yet (optional: you may still page earlier if your policy says so) |
| T+0… | Engineer opens the problem | Asks AI Assistant: summarize, next steps, draft status | Not required for AI text |
| T+0… | Chat readers | Read Dynatrace-posted AI text (same idea as Paige catch-up) | PD Advance chat optional |
| T+30m | Still Active, not closed | WF-B creates **one** PD incident (`dedup_key` = `dynatrace-<problem_id>`) | Pages on-call; schedule/escalation policy |
| Bridge / later | Meeting or coverage question | Dynatrace not used for transcript/coverage AI | Scribe / Shift if licensed |

### Solution picture (event path)

```
Event (Davis problem opens)
        │
        ├─► WF-A (replace Paige in chat)
        │     extract problem fields
        │     → Prompt generative AI (summary + 3 steps)
        │     → Slack Send  AND/OR  Teams Send
        │
        ├─► You (optional, interactive)
        │     Dynatrace UI → AI Assistant on that problem
        │
        └─► WF-B (only if still Active ≥ 30 minutes)
              preview payload
              → ONE PagerDuty Events API trigger
              → optional Slack/Teams “escalated” note
```

### How to build it (order)

| Step | What you do | Why |
|---|---|---|
| 1 | Confirm Davis Copilot / AI Units + Workflows | Without this, generative AI tasks fail |
| 2 | Connect **Dynatrace** Slack and/or Teams (not PD Advance chat) | AI text reaches chat without PD `/ai` Connected |
| 3 | Import **WF-A** from seq 12; bind test channels; keep inactive until tested | Replaces Paige catch-up on open |
| 4 | Import **WF-B**; Minimum duration **30m**; test routing key; `DRY_RUN` first | Replaces “escalate if ignored” |
| 5 | Practice: one primary talk channel; one PD service; no double-page | Avoid noise |
| 6 | Keep PD schedules; optionally keep Scribe/Shift later | Dynatrace cannot replace those |

### Example AI asks (interactive Assistant)

Use these on the open problem in Dynatrace (replaces typing `@PagerDuty …` in Slack):

```
Summarize this problem in five lines for on-call.
What are the top 3 investigation steps?
Draft a plain-text stakeholder status update.
What would confirm recovery?
```

### Example WF-A prompt (auto on open)

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

### Safety rules

| Rule | What it means |
|---|---|
| Test channels first | Use `#test-channel` / Teams test, not prod ops, until prompts look right |
| Test PD routing key | WF-B must page only you before prod |
| Fact-check AI | Assistant and workflow text can be wrong |
| One PD path | One service + stable `dedup_key`; do not also fire a second create-incident for the same problem |
| Humans own remediations | AI suggests steps; do not auto-run destructive fixes |

### Happy path vs common mistakes

| Path | What you see |
|---|---|
| Happy | Problem opens → Slack/Teams get AI summary → someone investigates → problem closes (WF-B never pages) |
| Happy late | Nobody acts → at 30m one PD page → on-call uses AI text + PD escalate |
| Mistake | Two PD integrations both create incidents for same problem → double page |
| Mistake | Rely on PD `/ai` Connected when admin blocked → use Dynatrace connectors instead |
| Mistake | Expect Dynatrace to run Scribe on Zoom → keep PD Scribe or take notes |

## Result

| Goal | Done when |
|---|---|
| Replace Paige-style help on event | WF-A posts AI summary to Slack/Teams on problem open |
| Replace interactive Q&A | You can ask AI Assistant on the problem in Dynatrace |
| Replace “escalate if ignored” | WF-B pages once after 30m if still Active |
| Keep what Dynatrace cannot do | PD still owns schedules; Scribe/Shift optional |
| Unblocked by PD Slack AI | Works even if PagerDuty AI Settings chat = Not Connected |

## Data flow map

```
App / host symptom
  → Dynatrace Davis detects problem (the “event”)
  → WF-A: generative AI summary
       → Slack channel
       → Teams channel (optional mirror)
  → Human: fact-check → investigate in Dynatrace (Assistant for more asks)
  → If still Active at 30m:
       WF-B → PagerDuty Events API (one incident)
            → on-call phone/app page
            → optional “escalated” note in Slack/Teams
  → Problem closed → stop; PD resolve if you wired close (optional later)
```

## Related files

| File | Purpose |
|---|---|
| `1-event-dynatrace-ai-replace-pd-ai.md` | This event-path solution |
| `../2026-10-17/9-dynatrace-ai-replace-pagerduty-ai/` | Full replace vs keep matrix |
| `../2026-10-17/11-dynatrace-ai-slack-teams-solution/` | Dual chat + 30m design |
| `../2026-10-17/12-dynatrace-ai-slack-teams-workflow-files/` | **WF-A / WF-B YAML** + prompts |
| `../2026-10-17/13-solution-summary-dt-ai-chat-pd/` | One-page solution summary |
| `../2026-10-17/16-dynatrace-ai-assistant-steps/` | Step-by-step Assistant setup |
| `1.sh` | Git one-liners (not run) |

## Commands

See `1.sh`. None have been run.

Import/test is done in the Dynatrace UI (Workflows). No shell required for the AI path.

```
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-18/1-event-dynatrace-ai-replace-pd-ai
git commit -m "event path dynatrace ai replace pagerduty ai"
git push
```
