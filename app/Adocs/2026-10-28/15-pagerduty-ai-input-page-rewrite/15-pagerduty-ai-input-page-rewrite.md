# PagerDuty AI Input Page Rewrite

```
Rewrite the input page for four agents?
  source and description → one block per agent
  SRE → incident + runbook + Teams question
  Scribe → bridge audio
  Insights → past incidents + one question
  Shift → schedule, left out of the Teams pilot
  names tick stays
  financial, health, My Number stay blank
  format → Text, Sound, Prompts, Body of knowledge
```

| Key point | Detail |
|---|---|
| What changed | The page no longer treats one incident card as every agent’s input. |
| Sample ids | INC-48291 and P-88421 are examples, not live tickets. |
| Sound | Ticked because Scribe listens to the bridge. |
| Shift | Described, then excluded from the pilot. |

## Summary

Replace the filled cells with four inputs. SRE reads the open incident and the question. Scribe reads the bridge. Insights reads incident history. Shift reads the schedule and is not part of this Teams pilot.

## Investigation

| Source | Finding |
|---|---|
| Screenshot | Data source, description, and sample are the single-incident catch-up. Sound is unticked. |
| Four agents | SRE, Scribe, Insights, and Shift do not share that card. |
| Teams pilot | SRE, Scribe, and an optional Insights question. Shift stays out. |
| Personal-data boxes | Employee display name is still the only category that applies. |

## Result

Paste the blocks below over the current cells.

### Data source

```
SRE: PagerDuty incident for the critical alert, the runbook linked on that service, and the question typed in the Microsoft Teams war-room channel. A person may paste one short Dynatrace or Splunk line. The full log store is not connected.
Scribe: audio of the Teams bridge. The note is written back to that channel.
Insights, if enabled: past PagerDuty incidents on the services this user can see, plus one question in Teams.
Shift: the on-call schedule. Not used in this Teams pilot.
```

### Data description

```
SRE fields: incident id, title, priority, status, service name, acknowledge time, escalation entries, assignee display name, linked runbook text, and the Teams question.
Scribe: spoken words on the bridge. The kept result is a text note.
Insights: counts and patterns of past incidents (service, priority, time). The question is text.
Shift is out of the pilot. Its data would be schedule names and override times, and it is not sent.
No policy file, claim file, medical file, or customer master record is loaded.
INC-48291 and P-88421 in the sample are example ids, not live tickets. A Dynatrace id is present only when the monitor put it on the PagerDuty event.
```

### Information types

```
[X] Names, Date of Birth, or contact details
    Employee display name, Teams identity, and names spoken on the bridge.
    Customer date of birth is not an input. The paging phone number stays in PagerDuty notification and is not the prompt text.

[ ] ID numbers (My Number, passport, customer/contract/employee IDs)
    My Number, passport, and customer or contract numbers are not inputs. Do not paste them.

[ ] Financial information
[ ] Health / medical information
[ ] Other sensitive information

Data owner: Technology DevOps for PagerDuty, Teams, Dynatrace, and Splunk. A specialist who pastes a line from another tool agrees that line first.
Confirm the ticks against 0570113E before the meeting.
```

### Samples

```
1) SRE
@PagerDuty Catch me up on INC-48291
Incident: INC-48291 | Title: High error rate on ebroker-api | Priority: P2 | Status: Acknowledged | Service: ebroker-api
Source event on the payload: Dynatrace problem P-88421
Assignee: on-call display name
Runbook: Check the upstream dependency, then the last deploy of this service.

2) Scribe
Bridge audio, sample of what is said: "Upstream timed out at 16:10 JST. Next check is the last deploy."
Kept result: that sentence as a text note in the Teams channel.

3) Insights, only if enabled
Question: Which service has the most P2 incidents in the last 14 days?
Input behind the question: past PagerDuty incidents for the services this user can see.

4) Shift
Not in this pilot. Do not send the schedule.
```

### Format

```
[X] Text
[ ] Image
[ ] Video
[X] Sound
[ ] Code
[X] Prompts
[X] Body of knowledge
[ ] Others

Text: incident fields, history, pasted line, Scribe note.
Sound: bridge audio for Scribe only.
Prompts: the Teams question for SRE and Insights.
Body of knowledge: the runbook linked on the service.
```

## Data flow map

```
SRE      [incident + runbook + question] → catch-up
Scribe   [bridge audio] → text note
Insights [past incidents + question] → answer
Shift    [schedule] → not sent
```

## Related files

| File | Role |
|---|---|
| `Daily Files/2026-10-28/12-pagerduty-ai-input-data/` | First version of this page. |
| `Daily Files/2026-10-28/14-four-agent-inputs/` | The split this page now uses. |
| `15.sh` | Copy and git one-liners. Review before running. |

## Commands

See [15.sh](15.sh). Do not commit or push until you ask for that.
