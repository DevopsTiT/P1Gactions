# PagerDuty AI Input Data

```
What goes into PagerDuty AI?
  incident record in PagerDuty
  the question typed in Microsoft Teams
  the thread on that incident
  a runbook linked to the service, when one is linked
  bridge audio only if Scribe is on
  a short pasted line only if a person pastes it
  not the whole Dynatrace or Splunk store
  not My Number, card numbers, bank details, or medical notes
```

| Key point | Detail |
|---|---|
| Designed input | The open incident, the Teams prompt, and the service runbook. |
| People data | Employee display name and the Teams identity of the person who asks. |
| Left unticked | Financial, health, and the other special-care categories. |
| Owner | Technology DevOps, for PagerDuty, Teams, Dynatrace, and Splunk on the tool sheet. |

## Summary

The model sees the PagerDuty incident, the question in Microsoft Teams, and any runbook already tied to that service. It does not receive the customer file, a card number, or a medical record. A pasted log line is allowed only when it is already safe to show in the war room.

## Investigation

| Source | What it shows |
|---|---|
| This slide | Source, description, personal-data ticks, a sample, and the format ticks. |
| Manual named on the slide | 0570113E Personal Information Protection Manual. Data owners must agree before their data is sent to an AI system. |
| PagerDuty AI in Teams | The assistant answers from the incident and the chat. Status drafts use the incident log and the Teams thread. |
| Scribe | Turns a bridge into a note. That path includes sound, and only when Scribe is enabled. |
| ALJ tool sheet | Technology DevOps owns PagerDuty, Dynatrace, and Splunk. |
| What this use case is not | Claims, premiums, My Number, passport, and medical records are not the job of the war-room assist. |

## Result

Paste the blocks below.

### Input data

```
Data source
- PagerDuty: the incident created for a critical alert (the event that Dynatrace, Splunk, synthetic, or another monitor sent into PagerDuty).
- Microsoft Teams: the war-room channel where the PagerDuty app posted that incident, and the question a person types there.
- PagerDuty service knowledge: the runbook or standard notes linked to that service, when a runbook is linked.
- Scribe, only if it is enabled: the audio of the bridge.
- A person may paste one short excerpt from Dynatrace or Splunk into the question. The full log store is not connected as the input.

Data description
Operational fields for one incident: incident id, title, priority, status, service name, acknowledge time, escalation entries, and the assignee display name.
The Teams text: the question and the replies already in that thread.
The runbook text for that service, when it exists.
The bridge recording only while Scribe is on.
No policy file, claim file, medical file, or customer master record is loaded.

Which types of information the dataset contains
[X] Names, Date of Birth, or contact details (email, phone, postal address), etc.
    In this dataset: the employee display name and the Teams identity of the on-call person and of people who type in the channel.
    Not in this dataset: customer date of birth. The phone number used for the page stays in PagerDuty notification. It is not the text of the prompt.

[ ] ID numbers (national IDs i.e. My Number), passport, customer/contract/employee IDs, etc.
    My Number, passport, and customer or contract numbers are not inputs. Do not paste them. A PagerDuty user id may appear as a system id of the assignee. That is not a national id.

[ ] Financial information (premiums, claims amounts, bank details, card numbers), etc.
[ ] Health / medical information, disability, etc.
[ ] Other sensitive information (Race, Sex life, Criminal Record, Victim of a crime, Participation in labor union, Domicile of origin, Creed, Social status/family origin, etc.)

Data owner
Technology DevOps owns the PagerDuty incident, the Teams war-room channel, Dynatrace, and Splunk. That team agrees these operational fields may be sent to PagerDuty AI for the pilot.
If a specialist pastes a line from SCOM, Nagios, VeloCloud, or an AWS tool, that team is the owner of the pasted line and agrees it before it is sent.
Confirm the ticks against 0570113E before the Gate 0 meeting.

Samples of input data
1) Question in Teams
@PagerDuty Catch me up on INC-48291

2) Incident fields the assist already has
Incident: INC-48291
Title: High error rate on ebroker-api
Priority: P2
Status: Acknowledged
Service: ebroker-api
Source event: Dynatrace problem P-88421
Assignee: Primary (on-call display name)

3) Optional paste, already safe for the war room
Error phrase: Address conversion failed. Upstream timeout.

4) Optional runbook line linked to the service
Check the upstream dependency health, then the last deploy of ebroker-api.
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

Text: incident fields, Teams thread, pasted excerpt, runbook.
Prompts: the question typed in Teams.
Body of knowledge: the runbook or service notes linked in PagerDuty.
Sound: the bridge, only when Scribe is enabled. The stored result used afterward is the text note.
```

## Data flow map

```
[Monitor event] → [PagerDuty incident fields]
                         |
[Teams question] --------+→ [PagerDuty AI]
[Runbook on the service]-+
[Bridge audio] ----------+   only if Scribe is on
                         |
                         v
                  catch-up / status draft / note
```

## Related files

| File | Role |
|---|---|
| `Daily Files/2026-10-28/11-pagerduty-ai-value-kpi-rewrite/` | The value this input is meant to produce. |
| `Daily Files/2026-10-28/5-pagerduty-ai-gate0-page3/` | PagerDuty does not train its models on this data. |
| `12.sh` | Copy and git one-liners. Review before running. |

## Commands

See [12.sh](12.sh). Do not commit or push until you ask for that.
