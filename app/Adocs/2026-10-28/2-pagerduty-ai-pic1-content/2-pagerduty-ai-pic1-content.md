# PagerDuty AI Pic1 Content

```
Gate 0 slide = Business Requirements (1/4)?
  box 1 Value Chain → tick IT + Operational Excellence + Data & AI
  box 2 Current process → two use cases, before AI, Teams only
  box 3 Pains → time, data volume, technical limit, cost, risk
                then positives to keep
  later slides → value, jobs, AXA reuse (leave them off pic 1)
```

| Key point | Detail |
|---|---|
| Which slide | Business Requirements (1/4). The first photo. |
| What to paste | Three blocks below. One block per empty box. |
| Chat channel | Microsoft Teams. The PagerDuty app already posts the incident there. |
| Time in the story | Before PagerDuty AI. The live path is Dynatrace, PagerDuty, and Teams. |

## Summary

Pic 1 asks only for the business area, how the work is done today, and what hurts. Paste the ticks into box 1, the two use cases into box 2, and the pains plus positives into box 3.

## Investigation

Checked the Gate 0 slide (Document Version 3.1) and the writing guide on the second photo.

| Check | What it showed |
|---|---|
| Slide title | Business Requirements (1/4), header “All Use Cases”. |
| Box 1 | Printed checkbox list. Instruction: put an X on the applicable choice. |
| Box 2 | Empty. Describe the process before AI. Split multiple processes into use case 1 and use case 2. |
| Box 3 | Empty, two bullet placeholders. Pains in budget, time, and technical limitation, plus positive aspects. |
| Guide | Name the tools, the people, and the step-by-step process. Say whether humans face more data than they can read in time. |
| Prior notes | Teams is the chat path. Dynatrace detects. PagerDuty pages and stays the incident record. |

## Result

Copy each block into the matching box. Leave every other checkbox blank.

### Box 1 — Business Value Chain

| Choice | Tick | Why this box |
|---|---|---|
| Information technology | X | The work is production incident response. |
| Operational Excellence and Project Management | X | The pain is slow catch-up and uneven status writing. |
| Data & AI | X | This Gate 0 request is an AI assist on that same process. |
| Every other printed choice | blank | Actuarial, Claims, Marketing, Security, and the rest are a different owner. |

Paste:

```
[X] Information technology
[X] Operational Excellence and Project Management
[X] Data & AI
```

### Box 2 — Current process

```
Use case 1 — On-call incident response (before AI)

Who: Primary on-call SRE. Stakeholders wait for a written status.

Tools in the live path today:
1) Dynatrace — detects the problem (errors, latency, saturation).
2) PagerDuty — system of record. Pages Primary by phone, push, or SMS. Records acknowledge, escalate, and resolve.
3) Microsoft Teams — the PagerDuty app posts the incident into the channel. People discuss there.
4) Optional Teams meeting — voice bridge. Notes stay in chat.

Steps:
1. Dynatrace raises a problem.
2. PagerDuty creates the incident and pages Primary.
3. The PagerDuty app posts the incident into the Teams channel.
4. Primary acknowledges in PagerDuty.
5. Primary rebuilds context by hand across Dynatrace, PagerDuty, and the Teams thread (recent changes, related incidents, what was already tried).
6. Primary writes the stakeholder status by hand.
7. After resolve, the team writes the post-incident note from memory, chat, and the tool timelines.

Use case 2 — Join or handoff mid-incident (before AI)

Who: Secondary, or the next SRE who was not on the first page.

Same three tools. The joiner opens Teams, PagerDuty, and Dynatrace and reads the thread to rebuild the timeline. There is no single catch-up summary. Logs, traces, past incidents, and chat are more than one person can read in the first minutes.
```

### Box 3 — Pains

```
Pains of the current process (before AI)

Time
- Primary and a late joiner spend the first minutes reconstructing the timeline across Dynatrace, PagerDuty, and Teams.
- Status updates and the post-incident note are written from scratch under pressure. Quality depends on who is on call.

Technical limitation
- Chat and bridge notes stay in Teams. They are not attached to the incident record.
- Logs, traces, related incidents, and chat are more than a human can scan while the service is still failing.

Budget / opportunity cost
- On-call time goes to catch-up and copy-paste. That time is then missing from diagnosis and the fix.

Risk
- A thin handoff lengthens recovery. Stakeholders receive an incomplete story.

Positive aspects to keep
- PagerDuty already pages the right person and records acknowledge, escalate, and resolve.
- Teams already receives the incident when the PagerDuty app is connected.
- Dynatrace remains the detector.
```

## Data flow map

```
USE CASE 1 (today, before AI)
  [Dynatrace problem]
        |
        v
  [PagerDuty incident] --page--> [Primary]
        |
        +--post--> [Teams channel]
                        |
                        v
              hand catch-up + hand-written status
                        |
                        v
              post-incident note from memory and chat

USE CASE 2 (today, before AI)
  [Secondary or next SRE]
        |
        +--reads--> Teams thread
        +--reads--> PagerDuty incident
        +--reads--> Dynatrace problem
        |
        v
  timeline rebuilt by hand
```

## Related files

| File | Role |
|---|---|
| `Daily Files/2026-10-28/1-pagerduty-ai-gate0-page1-business-requirements/` | Earlier same-day draft of this slide |
| `Daily Files/2026-10-22/21-pd-ai-teams-third-party-example/` | Example incident after AI is in Teams |
| `Daily Files/2026-10-22/20-pd-ai-teams-only-focus/` | Teams-only rule |
| `2.sh` | Copy and git one-liners. Review before running. |

## Commands

See [2.sh](2.sh). Do not commit or push until you ask for that.
