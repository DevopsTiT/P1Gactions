# Four Agent Inputs

```
Is the one incident card the input for all four agents?
  no
  SRE     → this incident + runbook + the Teams question
  Scribe  → bridge audio, then a text note
  Insights → past PagerDuty incidents + one Teams question
  Shift   → on-call schedule
            not part of the Teams pilot
  INC-48291 → sample only, not a real ticket
```

| Key point | Detail |
|---|---|
| What was wrong | One incident card was used as if every agent reads it. |
| SRE | Reads the open incident, the linked runbook, and the question. |
| Scribe | Reads the bridge. The kept result is a note. |
| Insights | Reads incident history, not one live assignee card. |
| Shift | Reads the schedule. Leave it off this Teams pilot. |

## Summary

Replace the single incident sample with four inputs. Only SRE uses that incident card. Scribe uses the bridge. Insights uses past incidents. Shift uses the on-call schedule and is outside the Teams pilot.

## Investigation

| Source | Finding |
|---|---|
| Earlier sample | INC-48291, ebroker-api, and Dynatrace P-88421 were written as an illustration for one catch-up. |
| Four agents | SRE, Scribe, Shift, and Insights. Each has its own input. |
| Teams pilot | SRE catch-up, Scribe note, and the status draft are in scope. Shift coverage notices are not. |
| Insights | One question in Teams is in scope only if Insights is enabled. Weekly notices are not. |
| Dynatrace id on the card | It is present only when the monitor put that id on the PagerDuty event. The agent does not log into Dynatrace for the whole problem. |

## Result

Paste this in place of sample 2 on the input slide.

```
The four agents do not share one input. INC-48291 below is a sample id, not a live incident.

1) SRE agent (product name Paige)
Input: the open PagerDuty incident, the runbook linked to that service, and the question in Microsoft Teams.
Optional: one short line a person pastes from Dynatrace or Splunk.
Sample:
@PagerDuty Catch me up on INC-48291
Incident: INC-48291
Title: High error rate on ebroker-api
Priority: P2
Status: Acknowledged
Service: ebroker-api
Source event on the PagerDuty payload: Dynatrace problem P-88421
Assignee: on-call display name
Runbook line: Check the upstream dependency, then the last deploy of this service.

2) Scribe
Input: audio of the bridge (a Teams meeting). The incident channel is where the note is delivered.
Sample: a short test bridge. Someone says the upstream timed out at 16:10 JST and the next check is the last deploy.
Stored result: the text note, not the raw audio, for the reviewer to match.

3) Insights
Input: past PagerDuty incidents on the services this user can see, plus one question in Teams.
Use this only if Insights is enabled.
Sample question: Which service has the most P2 incidents in the last 14 days?
Weekly notices are not an input for this pilot.

4) Shift
Input: the on-call schedule, escalation policy, and overrides.
Not the incident card.
Not in this Teams pilot. Coverage notices are not a Teams path. Do not send schedule data into the pilot.
```

## Data flow map

```
SRE      [this incident + runbook + Teams question] → catch-up
Scribe   [bridge audio] → text note in Teams
Insights [past incidents + one question] → an answer in Teams
Shift    [schedule] → not in this pilot
```

## Related files

| File | Role |
|---|---|
| `Daily Files/2026-10-28/12-pagerduty-ai-input-data/` | The input slide. Replace sample 2 with this set. |
| `Daily Files/2026-10-28/8-pagerduty-ai-agent-success-checks/` | Which agents are in the Teams pass. |
| `14.sh` | Copy and git one-liners. Review before running. |

## Commands

See [14.sh](14.sh). Do not commit or push until you ask for that.
