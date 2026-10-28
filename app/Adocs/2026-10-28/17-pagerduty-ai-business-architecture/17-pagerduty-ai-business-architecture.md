# PagerDuty AI Business Architecture

```
Critical signal
  detector already in use? → send to PagerDuty
  PagerDuty → incident + call + SMS + escalation policy
  BAM-India notified? → escalate into the war room
  war room → Microsoft Teams
  person asks PagerDuty AI → text reply
  person checks the text → act in PagerDuty
  story ready → ServiceNow and Silva correlation
  assist down? → incident and escalation still run
```

| Key point | Detail |
|---|---|
| New box | PagerDuty AI in the Microsoft Teams war-room channel. |
| What it returns | A catch-up, a status draft, or a bridge note. |
| Who checks it | A person in the war room, before they acknowledge, escalate, or send status. |
| What stays | Detection, the call, the SMS, the escalation policy, and ServiceNow / Silva. |

## Summary

Put PagerDuty AI on the existing 24x7 path, after the incident exists. Technology SREs and Application Support ask in Teams. The detectors, the page, and the correlation step keep their current owners.

## Investigation

| Source | Finding |
|---|---|
| Slide | Proposed Business Architecture, Document Version 3.1, page 10. The body is empty. |
| ALJ monitoring page | Five detection areas already named, plus network, VM, and cloud tools. |
| 24x7 diagram | Titled To Be. Signal, PagerDuty, BAM-India, war room, then ServiceNow and Silva. PagerDuty AI is not on that picture. |
| Gate 0 so far | Teams only. SRE and Scribe are in the pilot. Insights only if enabled. Shift is out. A person sends any status. |

## Result

Paste the blocks below onto the slide. The picture is the diagram. The role table is the legend.

### Slide title

Proposed Business Architecture

### One-line purpose

PagerDuty AI sits in the Microsoft Teams war room after PagerDuty has already opened a critical incident for ALJ and ADJ (P&C).

### Picture for the slide

```
Detectors already in use
  Dynatrace  Splunk  Selenium/Jenkins
  VeloCloud  Nagios  Aruba UXI
  SCOM       CloudWatch  X-Ray  Prometheus  Kibana
        |
        v
PagerDuty
  incident created
  call and SMS
  escalation policy
        |
        +----> BAM-India (24x7) is notified
        |
        v
War room
  Technology SREs
  Application Support
  Microsoft Teams channel
        |
        +----> PagerDuty AI   <--- the new box
                 SRE catch-up
                 status draft
                 Scribe bridge note
                 Insights only if enabled
        |
        v
A person checks the text
  then acknowledges, escalates, or sends the status
        |
        v
ServiceNow and Silva
  correlation stays here
```

Late joiners read the same Teams reply, then open the one tool their team owns.

| Who joins | Tool they open |
|---|---|
| Technology Infrastructure DBA | DEM for the relational database in Shinagawa DC |
| Technology Network Team | Nagios, VeloCloud, or Aruba UXI |
| Axa GO | SCOM |
| Cloud Broker | CloudWatch, X-Ray, Prometheus, or Kibana |

### Roles

| Role | What they do in this architecture |
|---|---|
| Technology DevOps | Owns the detectors that feed PagerDuty, and the PagerDuty account. |
| BAM-India | Receives the 24x7 call and SMS, then escalates. |
| Technology SREs | Ask in Teams, check the reply, and work the incident. |
| Application Support | Same Teams channel. Same check before they act. |
| Specialist teams | Join with their own tool after they have read the briefing. |
| Person on the bridge | Speaks the timeline. Scribe writes the note. A person keeps the note. |

### What each system does

| System | Place in the picture |
|---|---|
| Dynatrace | Application, user, synthetic, and host detection. Probable cause and SLO stay inside Dynatrace. |
| Splunk | Log search, dashboards, and log alerts. |
| Selenium and Jenkins | Scripted user checks that can raise an alert. |
| VeloCloud, Nagios, Aruba UXI | Local network and Japan network signals. |
| SCOM | VM health for Core IT and PlaaS, owned by Axa GO. |
| Cloud Broker tools | AWS or Open PaaS signals when the application uses them. |
| PagerDuty | Creates the incident, places the call and SMS, and runs the escalation policy. |
| Microsoft Teams | The war-room channel. This is the only place the pilot reads the AI reply. |
| PagerDuty AI | Writes the catch-up, the status draft, or the bridge note in that channel. |
| ServiceNow and Silva | Correlation after the war room has the story. |

### Pilot boundary

| Item | What to write |
|---|---|
| In the pilot | SRE catch-up and Scribe notes, on a test service. |
| Status | The tool drafts it. A person sends it. |
| Insights | One question about incidents the user can already see, and only if that agent is enabled. |
| Shift | No output. On-call schedule data is not sent. |
| Assist unavailable | The incident is still created. The escalation policy still runs. |
| Assist downtime on the form | 4 hours for the Teams assist. Call, SMS, and escalation keep the current PagerDuty availability. |

## Data flow map

```
detector signal
    -> PagerDuty incident
    -> call + SMS + escalation policy
    -> BAM-India
    -> Teams war room
    -> person asks
    -> PagerDuty AI text
    -> person checks
    -> action in PagerDuty
    -> ServiceNow / Silva
```

## Related files

| File | What it is |
|---|---|
| 17-pagerduty-ai-business-architecture-follow.txt | Same paste, easy to copy. |
| 0-pic.md | Picture and flow only. |
| 1-investigation.md | What was checked. |
| 2-result.md | What to paste. |
| 3-glossary.md | Words on this slide. |
| 17.sh | Copy commands. Run them yourself. |
