# PagerDuty AI Agent Success Checks

```
Does section 8 prove the agents work?
  current five checks → the Teams reply matches the incident
  they do not → run SRE, Scribe, and the status draft as separate jobs
  Shift → leave out of a Teams-only pass
  Insights weekly notes → leave out; one Teams question only if Insights is on
```

| Key point | Detail |
|---|---|
| What the five checks prove | Microsoft Teams is connected, a reply appears, and a reviewer can match the incident id and state to PagerDuty. |
| What they skip | A separate result from the SRE agent, from Scribe, and from the status-draft feature. |
| Teams-only pass | SRE catch-up, Scribe note, and a status draft a person still sends. |

## Summary

The current acceptance text shows the assistant answered and the facts match. To show the agents work, add one visible result for each agent you turn on. For this pilot that is the SRE catch-up and the Scribe note. Shift stays off the pass list because its coverage notices are not a Teams path.

## Investigation

| Source | What it shows |
|---|---|
| Section 8 as written | Five checks: Teams connected, a reply appears, five incidents match PagerDuty, the status stays a draft, and paging still runs if the assist is down. |
| PagerDuty AI product | The assistant is the chat. The agents are separate jobs: SRE, Scribe, Shift, and Insights. Status draft is its own feature. |
| Teams-only notes | SRE questions and Scribe notes can be shown in Microsoft Teams. Shift coverage notices are not the Teams path. Insights can answer one question in Teams. Its weekly notices are not part of this pass. |
| Gate 0 safety | The page, the call, the SMS, and the escalation policy must still run when the assist is down. |

## Result

Use the block below if the success bar is “the in-scope agents worked.”

```
Acceptance is a checked result from each in-scope agent on a test PagerDuty service. Do not page the production rota to prove it.

In scope for this Teams pilot: SRE catch-up, Scribe note, status draft.
Out of scope: Shift coverage notices.

Pass when all of these are true:

1. Microsoft Teams shows Connected and Enabled for PagerDuty AI. The test user is linked. SRE and Scribe are enabled for the test service.
2. SRE catch-up. On a test incident, a person asks in the Teams channel for a catch-up. A reply appears in that channel. The incident id and the open or acknowledged state match PagerDuty. If the reply states a cause, the reviewer can point to the same fact on the Dynatrace problem or the incident timeline.
3. Status draft. The assist produces a stakeholder status as a draft. A person sends it. The tool does not send it on its own.
4. Scribe. A short test bridge is held. A note arrives in the Teams channel or on the incident. The reviewer can match one time or one decision from the bridge to that note.
5. Repeat the SRE catch-up on five test incidents agreed with the on-call lead. All five are marked usable.
6. With the AI assist unavailable, the test incident is still created in PagerDuty and the escalation policy still runs.

Insights is a pass item only if it is enabled. One on-demand question in Teams returns an answer the reviewer can trace to PagerDuty data. Weekly notices are not required.
Shift is not a pass item for this pilot.
```

| Agent or feature | In the old five checks | Add this to show it worked |
|---|---|---|
| Assistant reply | A reply appears and the id matches. | Keep that. It is the SRE catch-up in check 2. |
| SRE agent | Only as a generic reply. | The catch-up must be the SRE ask, and the facts must match. |
| Status draft | The draft is not auto-sent. | Keep that as its own check. |
| Scribe | Not covered. | A test bridge produces a note a reviewer can match. |
| Insights | Not covered. | One Teams question, and only if Insights is enabled. |
| Shift | Not covered. | Leave it out of the Teams-only pass. |

## Data flow map

```
[Test incident]
    |
    +-- SRE ask in Teams → reply matches PagerDuty id and state
    |
    +-- status draft → person sends it
    |
    +-- test bridge → Scribe note matches one fact from the bridge
    |
    v
five incidents pass

[Assist down] → PagerDuty still creates the incident and escalates
```

## Related files

| File | Role |
|---|---|
| `Daily Files/2026-10-28/7-pagerduty-ai-acceptance-criteria/` | The five checks this page revises. |
| `Daily Files/2026-08-25/10-pagerduty-ai-agents-teams-only/` | Which agents can be shown in Teams. |
| `8.sh` | Copy and git one-liners. Review before running. |

## Commands

See [8.sh](8.sh). Do not commit or push until you ask for that.
