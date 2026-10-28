# PagerDuty AI Data Flow

```
Data Flow slide
  use case → 24x7 critical-incident catch-up in Teams
  personal information? → employee name or Teams identity only
  mark those hops with the red dot
  customer, financial, health fields → leave them off this picture
  paging phone → stays in the PagerDuty notification
  Shift schedule → do not draw it; it is not sent
```

| Key point | Detail |
|---|---|
| Use case name | 24x7 critical-incident catch-up in Microsoft Teams. |
| Red dot | Employee display name, Teams identity, or a name spoken on the bridge. |
| What the model returns | Text in the same Teams channel. |
| Who checks it | A person, before acknowledge, escalate, or send. |

## Summary

Draw one flow for the war-room assist. The red dot sits only on employee names. The incident id, the service name, the runbook, and the question text are operational data.

## Investigation

| Source | Finding |
|---|---|
| Slide | Data Flow, Document Version 3.1, page 11. Use Case is blank. The banner says to mark personal information with the red dot. |
| Input page | Names and contact is the only privacy tick. It covers employee display name, Teams identity, and names spoken on the bridge. |
| Phone | The paging number stays in the PagerDuty notification. It is not prompt text. |
| Shift | Schedule names are not sent in this pilot. |
| Sample ids | INC-48291 and P-88421 are examples, not live tickets. |

## Result

Paste the blocks below. Put the red dot on the three hops marked 🔴.

### Use case

```
24x7 critical-incident catch-up in Microsoft Teams
ALJ and ADJ (P&C), after PagerDuty has opened the incident
```

### Legend

```
🔴  personal information
    employee display name, Teams identity, or a name spoken on the bridge
    customer date of birth, My Number, financial fields, and health fields are not on this flow
```

### Picture

```
Detector
  Dynatrace, Splunk, Selenium/Jenkins, or a network tool
  data: service name, alert text, problem id
        |
        v
PagerDuty
  incident id, title, priority, status, service, timeline
  🔴 assignee display name
  call and SMS use the on-call number inside PagerDuty
  that number is not copied into the AI prompt
        |
        +----> BAM-India receives the call and SMS
        |
        v
Microsoft Teams
  🔴 identity of the person who asks
  question text
  optional one technical line from Dynatrace or Splunk
        |
        +----> runbook linked on the service (procedure text)
        |
        v
PagerDuty AI
  SRE    incident fields + 🔴 assignee name + runbook + question
  Scribe bridge audio, which can include 🔴 a spoken name
         kept result is a text note
  Insights, only if enabled
         past incidents this user can see, plus one question
  Shift  no data sent
        |
        v
Text back in the Teams channel
  catch-up, status draft, or bridge note
  a spoken name can be repeated, so keep 🔴 on that note
        |
        v
A person checks the text
  then acknowledges, escalates, or sends the status
        |
        v
ServiceNow and Silva
  correlation after the person acts
  the assist does not write this hop
```

### What moves on each hop

| Hop | Data that moves | Red dot |
|---|---|---|
| Detector to PagerDuty | Service name, alert text, problem id when the monitor put it on the event. | No. |
| PagerDuty notification | Call and SMS to the on-call number. | The number stays in PagerDuty. It is not sent to the model. |
| PagerDuty to the assist | Incident id, title, priority, status, service, timeline, linked runbook. | 🔴 Assignee display name. |
| Person to Teams | The question, and at most one technical line. | 🔴 Teams identity of the person who asks. |
| Bridge to Scribe | Spoken words on the bridge. | 🔴 Any employee name spoken on the bridge. |
| Insights, if enabled | Past incidents on services this user can see, plus one question. | 🔴 The asker’s Teams identity. Incident history itself is operational. |
| Assist to Teams | Catch-up, status draft, or bridge note. | 🔴 If the note repeats an employee name. |
| Person to ServiceNow / Silva | The correlation the person files after they act. | Follow the existing ticket rules. The assist does not write this hop. |

## Data flow map

```
detector signal
    -> PagerDuty incident
         🔴 assignee display name
    -> Teams question
         🔴 asker identity
    -> PagerDuty AI
         SRE text
         Scribe audio -> text note (🔴 spoken name)
         Insights question, only if enabled
    -> Teams reply (🔴 if a name is repeated)
    -> person checks
    -> PagerDuty action
    -> ServiceNow / Silva
```

## Related files

| File | What it is |
|---|---|
| 18-pagerduty-ai-data-flow-follow.txt | Same paste, easy to copy. |
| 0-pic.md | Picture and flow only. |
| 1-investigation.md | What was checked. |
| 2-result.md | What to paste. |
| 3-glossary.md | Words on this slide. |
| 18.sh | Copy commands. Run them yourself. |
