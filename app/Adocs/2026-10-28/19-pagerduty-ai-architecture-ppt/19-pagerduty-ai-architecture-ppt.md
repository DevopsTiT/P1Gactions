# PagerDuty AI Architecture Slide

```
Blank architecture slide
  want the EIP style? → zones, one hub, a label on every line, one yellow note
  which picture? → the 24x7 war-room assist
  new box? → PagerDuty AI inside the Teams zone
  EIP mediators on this slide? → leave them off
  Shift? → leave it off
```

| Key point | Detail |
|---|---|
| Slide title | Proposed Business Architecture |
| Picture type | Zones and a hub, in the same style as the EIP architecture page. |
| Hub | PagerDuty. It already creates the incident and runs call, SMS, and escalation. |
| New box | PagerDuty AI, inside the Microsoft Teams war room. |

## Summary

Draw six boxes. PagerDuty sits in the center. Detection feeds it. BAM-India and the war room sit on the right. The yellow note says the only new box is PagerDuty AI.

## Investigation

| Source | Finding |
|---|---|
| Example picture | Confluence page “1-EIP Architecture.” Zones on top, a hub in the middle, protocol labels on the lines, and one yellow note. |
| Gate 0 architecture | The war-room assist. Detectors, PagerDuty, BAM-India, Teams, then ServiceNow and Silva. |
| What stays off this slide | EIP mediators, the Singapore layout, and the Shift schedule. Those are a different system from this pilot. |

## Result

Build one PowerPoint slide with the shapes below. Read it left to right, then down, the same way the EIP page is read.

### Slide header

```
Proposed Business Architecture

This picture is the 24x7 war-room assist for ALJ and ADJ (P&C).
It shows the pilot path after a critical event already exists.
Detection, paging, and correlation are already in use.
The only new box is PagerDuty AI in Microsoft Teams.
```

### How to place the shapes

| Shape | Where on the slide | What to write inside |
|---|---|---|
| Box 1 | Top left | Detection zone. Providers of the signal. |
| Box 2 | Center | PagerDuty. The hub. |
| Box 3 | Top right | BAM-India 24x7. Consumer of the page. |
| Box 4 | Middle right | War room. Consumers of the briefing. |
| Box 5 | Inside the lower part of box 4, with a thicker border | PagerDuty AI. The new box. |
| Box 6 | Bottom center | ServiceNow and Silva. |
| Yellow note | Top right, beside box 3 | The constraint in the note below. |

### Box text

```
BOX 1 — DETECTION ZONE
Providers of the signal
Dynatrace
Splunk
Selenium / Jenkins
VeloCloud, Nagios, Aruba UXI
SCOM
CloudWatch, X-Ray, Prometheus, Kibana
Owner: the team that already owns that tool
Technology DevOps owns Dynatrace, Splunk, Selenium/Jenkins, and PagerDuty

BOX 2 — PAGERDUTY
Hub
Incident
Escalation policy
Call and SMS
Owner: Technology DevOps

BOX 3 — BAM-INDIA
24x7 consumer of the page
Receives the call and SMS
Escalates into the war room

BOX 4 — WAR ROOM
Consumers of the briefing
Technology SREs
Application Support
Microsoft Teams channel
Late joiner reads the same reply, then opens one tool:
  DBA → DEM
  Network → Nagios, VeloCloud, or Aruba UXI
  Axa GO → SCOM
  Cloud Broker → CloudWatch, X-Ray, Prometheus, or Kibana

BOX 5 — PAGERDUTY AI
Draw this inside Box 4
SRE catch-up
Status draft
Scribe bridge note
Insights, only if enabled

BOX 6 — SERVICENOW AND SILVA
Correlation
Filed after a person has checked the text and acted
```

### Lines and the label on each line

| From | To | Label on the line |
|---|---|---|
| Box 1 Detection | Box 2 PagerDuty | critical event |
| Box 2 PagerDuty | Box 3 BAM-India | call / SMS |
| Box 2 PagerDuty | Box 4 War room | escalation |
| Box 4 Teams | Box 5 PagerDuty AI | Teams question |
| Box 4 bridge | Box 5 Scribe | bridge audio |
| Box 5 PagerDuty AI | Box 4 Teams | text reply |
| Box 4 person | Box 2 PagerDuty | person checks, then acts |
| Box 4 person | Box 6 ServiceNow / Silva | correlation |

### Yellow note

```
PagerDuty AI is the only new box.
It sits in the Teams channel.
The detection tools stay in the detection zone.
Call, SMS, and the escalation policy stay in PagerDuty.
Shift is not on this picture. Schedule data is not sent.
If the assist is down, the incident is still created and the escalation policy still runs.
```

### Footer

```
Employee display name, Teams identity, and a name spoken on the bridge are the personal-information marks.
Put the red dot on those three items on the Data Flow slide.
```

## Data flow map

```
[ Detection zone ]
        | critical event
        v
[ PagerDuty hub ] --call / SMS--> [ BAM-India ]
        | escalation
        v
[ Teams war room ]
        | Teams question / bridge audio
        v
[ PagerDuty AI ]
        | text reply
        v
person checks
        | acts                 | correlation
        v                       v
[ PagerDuty ]            [ ServiceNow / Silva ]
```

## Related files

| File | What it is |
|---|---|
| 19-pagerduty-ai-architecture-ppt-follow.txt | Same slide text, easy to copy. |
| 0-pic.md | The picture only. |
| 1-investigation.md | What was checked. |
| 2-result.md | What to draw. |
| 3-glossary.md | Words on this slide. |
| 19.sh | Copy commands. Run them yourself. |
