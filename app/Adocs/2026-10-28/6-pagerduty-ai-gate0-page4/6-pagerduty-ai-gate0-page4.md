# PagerDuty AI Gate0 Page4

```
Business Requirements (4/4)?
  users → Employees in Support Function
          department: Technology DevOps (on-call) and Application Support
  consumers → Employees who read the reply and do not type the question
  customers / brokers → affected by the incident, not readers of the AI text
  success → test incident in Teams, reply matches PagerDuty, person sends any status
  downtime → 4 hours for the Teams assist only
             the call, SMS, and escalation policy stay on current PagerDuty
  headcount → leave as “count the rota”; do not invent a number
```

| Key point | Detail |
|---|---|
| Slide | Business Requirements (4/4). Sections 7, 8, and 9. |
| Who types the question | On-call people in the Microsoft Teams incident channel. |
| Who only reads | Specialist teams and anyone who receives the status draft. |
| Downtime number | Applies to the assist. It does not apply to paging. |

## Summary

The users are employees in Technology DevOps and Application Support. Success is a checked reply on test incidents in Teams. If the assist is down for up to four hours, the war room uses today’s manual catch-up, and PagerDuty still places the call and SMS.

## Investigation

| Source | What it shows |
|---|---|
| This slide | User group, line of business, department, consumers of the output, acceptance criteria, and maximum downtime. |
| Form examples | Document-accuracy and knowledge-library examples are for other AI types. This use case is a Teams assist on an existing incident. |
| ALJ tool sheet | PagerDuty, Dynatrace, and Splunk are owned by Technology DevOps. |
| 24x7 diagram | BAM-India receives the notification. The war room is Technology SREs and Application Support. Specialists join from DBA, Network, Axa GO, or Cloud Broker. |
| Page 3 | The product to implement is PagerDuty AI in Microsoft Teams. A person confirms the reply before acting. |
| Headcount | No roster size is printed on the monitoring page or the tool sheet. |

## Result

Paste the three sections below. Leave Number of users as a count of the real rota.

### 7. Stakeholders

```
Users of the AI system (people who will ask in Microsoft Teams)

[X] Employees
[ ] Brokers/Agents
[ ] Customers
[ ] General public
[ ] Others

Number of users: Count the pilot rota. Do not guess. Scope is the on-call Primary, the Secondary, and the Application Support people who will be linked to Teams for the test channel.
Line of Business: [X] Support Function
Department Name: Technology DevOps, with Application Support in the same war-room channel.

People who consume the AI output (they use the reply and may not type the question)

[X] Employees
[ ] Brokers/Agents
[ ] Customers
[ ] General public
[ ] Others

Number of users: Count after the pilot channel is named. This is larger than the typing group.
Department Name: BAM-India (24x7 desk), Technology Infrastructure DBA, Technology Network Team, Axa GO, Cloud Broker, and the managers who receive the status draft.

Other stakeholders impacted
Customers and brokers of ALJ and ADJ (P&C) feel the underlying incident. They do not read the AI reply. ServiceNow and Silva handlers still record the correlation. The tribe solution architect confirms the AXA Japan line on page 2 before the Gate 0 meeting.
```

### 8. Acceptance criteria

```
This is not a document-understanding or knowledge-library case. Acceptance is a checked reply on test incidents. Use a test PagerDuty service. Do not page the production rota to prove it.

Pass when all of these are true:

1. Microsoft Teams shows Connected and Enabled for PagerDuty AI, and the test user is linked.
2. On a test incident, a person asks in the Teams channel and a reply appears in that channel.
3. On five test incidents agreed with the on-call lead, a Technology DevOps reviewer marks the reply usable only when the incident id and the open or acknowledged state match the PagerDuty incident. If the reply states a cause, the reviewer can point to the same fact on the Dynatrace problem or the incident timeline.
4. A status draft stays a draft until a person sends it.
5. With the AI assist unavailable, the test incident is still created in PagerDuty and the escalation policy still runs. The page does not depend on the assist.

Success for the pilot is those five checks. A later target, such as a change in time-to-catch-up, waits until the pilot has a before-and-after measure. No accuracy percentage is set on this form.
```

### 9. Maximum allowable downtime

```
4 hours for the PagerDuty AI reply in Microsoft Teams.

Why this number: the assist is not on the detection path and not on the paging path. If Teams or the assist is down, BAM-India and the war room use today’s manual catch-up across Dynatrace, Splunk, and PagerDuty. The call, the SMS, and the escalation policy keep the availability they have today. This 4-hour figure does not apply to those.

Revisit the number after the pilot if the on-call lead wants a tighter target, or if the PagerDuty agreement states a different figure for the Advance add-on.
```

## Data flow map

```
WHO TYPES
  Technology DevOps on-call
  Application Support in the war-room channel
        |
        v
  [Teams question] → [PagerDuty AI reply]
        |
        +-- reviewer checks it against the PagerDuty incident
        |
        v
WHO READS
  BAM-India
  DBA / Network / Axa GO / Cloud Broker
  managers who receive the status a person chose to send

IF THE ASSIST IS DOWN (up to 4 hours)
  [Dynatrace / Splunk] → manual catch-up
  [PagerDuty] → call, SMS, escalation policy still run
```

## Related files

| File | Role |
|---|---|
| `Daily Files/2026-10-28/5-pagerduty-ai-gate0-page3/` | The product this page accepts. |
| `Daily Files/2026-10-28/3-pagerduty-ai-pic1-alj-tools/` | Departments and the 24x7 path. |
| `6.sh` | Copy and git one-liners. Review before running. |

## Commands

See [6.sh](6.sh). Do not commit or push until you ask for that.
