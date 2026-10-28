# Slides 18 And 19 Explained

```
Presenter opens the deck
  which slide? → 19 first, then 18
  19 answers → which system sits in which box
  18 answers → which facts move, and where the red dot goes
  someone asks about EIP mediators? → those stay on the EIP page
  someone asks about customer data? → point at the three red dots on slide 18
```

| Key point | Detail |
|---|---|
| Show first | Slide 19, the zone picture. |
| Show second | Slide 18, the data-flow picture. |
| One sentence for 19 | PagerDuty is the hub. PagerDuty AI is the only new box, inside Teams. |
| One sentence for 18 | The red dot is an employee name. Three places carry it. |

## Summary

Slide 19 tells the room which box does which job. Slide 18 tells the room which facts travel between those boxes, and which of those facts are personal information.

## Investigation

| Source | Finding |
|---|---|
| Item 18 | Data Flow slide. Use case is the 24x7 Teams catch-up. Red dot marks employee names. |
| Item 19 | Proposed Business Architecture, drawn as zones and a hub. |
| Meeting order | The zone picture is easier to follow first. The data-flow picture then shows what moves. |

## Result

Paste each script into the PowerPoint notes pane for that slide.

### Slide 19 — say this

```
This slide is the business picture for the 24x7 war room.
Read it the same way you read the EIP architecture page:
zones as boxes, one hub in the center, and a label on every line.

The detection zone on the left provides the signal.
Dynatrace, Splunk, Selenium, and the network, VM, and cloud tools stay there.
Each tool keeps its current owner.

PagerDuty is the hub.
It already creates the incident, places the call and SMS, and runs the escalation policy.
Technology DevOps owns that hub.

The call and SMS go to BAM-India.
BAM-India is the consumer of the page. They escalate into the war room.

The war room is Microsoft Teams.
Technology SREs and Application Support are the consumers of the briefing.
A late joiner from DBA, Network, Axa GO, or Cloud Broker reads that same briefing, then opens the one tool their team owns.

PagerDuty AI is the thicker box inside Teams.
That is the only new box on this slide.
It writes a catch-up, a status draft, or a bridge note.
A person checks the text, then acts back in PagerDuty.

ServiceNow and Silva stay at the bottom.
Correlation happens after the person has acted.

The yellow note is the constraint.
Shift is not drawn, because schedule data is not sent.
If the assist is down, the incident is still created and the escalation policy still runs.
```

### Slide 19 — if someone asks

| Question | Answer in the room |
|---|---|
| Why is PagerDuty in the center? | Every critical event already passes through it. The call, the SMS, and the escalation policy start there. |
| Why is the AI inside Teams? | The pilot reads and writes in the war-room channel. |
| Where is Dynatrace Assist? | It stays inside Dynatrace, in the detection zone. This slide adds the Teams briefing. |
| Why is there no Shift box? | The on-call schedule is not sent in this pilot. |
| Is this the EIP mediator picture? | This slide uses that layout. The mediators stay on the EIP page. |

### Slide 18 — say this

```
This slide is the same path, drawn as data instead of systems.
The use case is the 24x7 critical-incident catch-up in Microsoft Teams,
for ALJ and ADJ (P&C), after PagerDuty has opened the incident.

Start at the detector.
The data on that hop is the service name, the alert text, and the problem id when the monitor put it on the event.

PagerDuty stores the incident.
The fields that move onward are the id, title, priority, status, service, timeline, and the linked runbook.
The red dot here is the assignee display name. That is an employee name.

The call and SMS still use the on-call number inside PagerDuty.
That number stays in the notification. It is not copied into the prompt.

In Teams, the person types a question.
The red dot here is their Teams identity.
They may paste one technical line from Dynatrace or Splunk.

Scribe listens to the bridge.
The red dot here is any employee name spoken on the bridge.
The kept result is a text note in the channel.

Insights is on the picture only if that agent is enabled.
It sees past incidents this user can already see, plus one question.

Shift has no arrow. We do not send the schedule.

The reply comes back as text.
If the note repeats an employee name, the red dot stays on that note.
A person checks it before they acknowledge, escalate, or send a status.

ServiceNow and Silva are the last hop.
The person files the correlation. The assist does not write that hop.

Customer date of birth, My Number, financial fields, and health fields are not on this picture.
```

### Slide 18 — the three red dots

| Where the red dot sits | What it marks |
|---|---|
| PagerDuty incident | Assignee display name. |
| Teams question | Identity of the person who asks. |
| Bridge, and the note if it repeats a name | An employee name spoken on the bridge. |

### How the two slides fit

```
Slide 19  which box
    detection zone -> PagerDuty hub -> BAM-India
                   -> Teams war room -> PagerDuty AI
                   -> ServiceNow / Silva

Slide 18  which fact
    alert text -> incident fields + red-dot name
               -> Teams question + red-dot identity
               -> bridge audio + red-dot spoken name
               -> text reply
               -> person acts
```

## Data flow map

```
open slide 19
    -> name the hub (PagerDuty)
    -> point at the thicker box (PagerDuty AI)
    -> read the yellow note
open slide 18
    -> walk the same path as data
    -> stop on each red dot
    -> say the phone number stays in the notification
```

## Related files

| File | What it is |
|---|---|
| 20-slides-18-19-ppt-explain-follow.txt | The two scripts, easy to copy into notes. |
| 0-pic.md | The order to present. |
| 1-investigation.md | What was checked. |
| 2-result.md | The scripts. |
| 3-glossary.md | Words used while presenting. |
| 20.sh | Copy commands. Run them yourself. |
