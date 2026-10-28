# PagerDuty AI Gate0 Page2

```
Business Requirements (2/4)?
  capability → Other workplace assistants + a short Other explanation
  DU boxes → leave blank (banner says not a document-understanding case)
  AXA Japan → Yes for Dynatrace and Splunk detection AI
              architect recommendation line stays open
  Group library → leave Yes unchecked until the library is searched
  value → war-room catch-up, status draft, bridge notes
          detection, paging, and Silva stay where they are
```

| Key point | Detail |
|---|---|
| Slide | Business Requirements (2/4). Sections 4 and 5. |
| Product | PagerDuty AI in Microsoft Teams, after the incident already exists. |
| Banner | “Not Required for Document Understanding (DU)”. Leave the document boxes blank. |
| Architect | The form asks for that person’s recommendation. The monitoring page does not contain one. |

## Summary

Tick workplace assistant, name the Teams war-room assist, and record the detection AI that ALJ already runs. Leave the Group library box unchecked until someone searches it. The value box is a shared catch-up and a status draft, with Dynatrace, PagerDuty paging, and Silva left in place.

## Investigation

| Source | What it shows |
|---|---|
| This slide | Section 4 asks for capability ticks, an AXA Japan search, and a Group AI Use Case Library search. Section 5 asks which pains are eased and which gains appear. |
| Blue banner | Document understanding is not required for this use case. |
| Section 4 instruction | Consult the tribe solution architect or enterprise architect before the Gate 0 ideation meeting, and write their recommendation. |
| Section 5 instruction | Tie the tool to the pains already written, then add gains. |
| ALJ monitoring page | Dynatrace and Splunk already apply models inside detection and log analytics. PagerDuty creates the incident and notifies by call and SMS. |
| 24x7 diagram | The war room still writes context. ServiceNow and Silva are the correlation step. The diagram title includes “To Be”. |
| Teams-only notes | The assist, when added, is asked in Microsoft Teams. Shift-style coverage DMs are outside this slide. |

## Result

Paste the blocks below into the matching cells.

### 4. Capability

| Choice | Tick | Why |
|---|---|---|
| Other workplace assistants | X | The user is an on-call SRE or Application Support person, not a customer. |
| Other (Please explain) | X | The list has no “incident war-room briefing” box. The explain line carries that purpose. |
| Every document, claims, sales, fraud, and code box | blank | The banner says this is not a document-understanding case. Those jobs are a different owner. |

```
[X] Other workplace assistants
[X] Other (Please explain):
PagerDuty AI in Microsoft Teams for the 24x7 war room.
After PagerDuty has created the incident, a person asks in the Teams channel for a catch-up, starter checks, and a status draft. A bridge can be turned into notes.
Dynatrace and Splunk keep detection. PagerDuty keeps the call, the SMS, and the escalation policy. ServiceNow and Silva keep correlation.
```

### 4. AXA Japan solutions already explored

```
[X] Yes.

Explored on the ALJ and ADJ (P&C) monitoring page and the tool sheet. Technology DevOps already runs:
- Dynatrace — discovery, HTTP/S transactions, probable cause, SLOs, and host metrics. Models already sit inside detection.
- Splunk — log search, dashboards, and alerts.
- PagerDuty — incident creation, call, SMS, and the escalation policy for critical alerts.

Those three stay. The detection models do not write the war-room briefing.

Architect recommendation:
Leave this line for the tribe solution architect or enterprise architect. The monitoring page does not record their recommendation. Take this point to that consult before the Gate 0 meeting: keep Dynatrace and Splunk for detection, and add PagerDuty AI in Microsoft Teams only for the briefing after the incident exists.
```

### 4. Group AI Use Case Library

```
[ ] Yes. Leave unchecked.

Not named on the ALJ monitoring page or the tool sheet. Before the meeting, search the Group AI Use Case Library for an on-call incident assistant (PagerDuty AI, Microsoft Teams). If another entity already uses one, write the entity name and the solution name here.
```

### 5. Value offered

```
Pains eased (Business Requirements 1/4, section 3):

- The first minutes are tool-hopping across Dynatrace, Splunk, synthetic results, and sometimes network, database, VM, or AWS tools. In Teams, a person can ask for a catch-up on the open incident. That reply is the shared starting picture. They still open the detector to confirm.
- Stakeholder status is written from scratch, and the wording depends on who is in the war room. The assistant can draft the status. A person sends it.
- A late joiner from DBA, Network, Axa GO, or Cloud Broker repeats the reading. They can read the same Teams reply, then open the one tool their team owns.
- Bridge notes stay with the people who were on the call. The assist can keep a written note of the bridge in the Teams channel.

These stay as they are:
- Dynatrace and Splunk detect. A person brings the important finding into the Teams question.
- PagerDuty places the call and SMS and runs the escalation policy.
- ServiceNow and Silva remain the correlation step.
- A person confirms the draft before they acknowledge, escalate, or update stakeholders.

Additional gains:
- Technology SREs and Application Support see one reply in the same channel.
- BAM-India spends less of the first minutes copying a timeline between tools.
- Status wording is steadier from one on-call week to the next.
- A specialist sees the briefing before opening DEM, Nagios, VeloCloud, SCOM, or the AWS tools.
```

## Data flow map

```
[Dynatrace / Splunk / synthetic / network]
        |
        v
[PagerDuty incident] --call/SMS--> [BAM-India]
        |
        v
[Teams channel]
   person asks PagerDuty AI
   reply: catch-up, starter checks, status draft, bridge note
        |
        +-- person confirms, then acts in PagerDuty
        |
        v
[ServiceNow / Silva]  correlation stays here
```

## Related files

| File | Role |
|---|---|
| `Daily Files/2026-10-28/3-pagerduty-ai-pic1-alj-tools/` | Page 1 paste. Pains referred to here. |
| `Daily Files/2026-10-22/20-pd-ai-teams-only-focus/` | Teams-only boundary. |
| `4.sh` | Copy and git one-liners. Review before running. |

## Commands

See [4.sh](4.sh). Do not commit or push until you ask for that.
