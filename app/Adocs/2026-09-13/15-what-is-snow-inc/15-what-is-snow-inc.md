# What Is ServiceNow INC

```
See "ServiceNow INC" and wonder what INC is?
  │
  └─ INC = Incident
       → a ticket that records an unplanned outage/issue
       → number looks like INC0012345
       → not the same as a Dynatrace "Problem" (different system)
```

## Short takeaway

| Key point | Detail |
| --- | --- |
| INC means | **Incident** |
| What it is | A ServiceNow ticket for something that went wrong |
| Number look | Usually `INC` + digits, e.g. `INC0012345` |
| Why we create it | Tracking, assignment, SLA, audit in ITSM |
| vs Dynatrace Problem | Problem = detect in monitoring; INC = work ticket in ServiceNow |

## Summary

In ServiceNow, **INC** is short for **Incident**. When our workflow says “create ServiceNow INC,” it means “open an Incident ticket” so ops can track and resolve the issue with a formal record. The workflow stamps that ticket with the Dynatrace Problem ID (`correlation_id`) so close can find it later.

## Plain explanation

| Term | What it means | Why you care |
| --- | --- | --- |
| ServiceNow | IT service management tool (tickets, changes, CMDB) | Where many companies track work |
| Incident | Unplanned interruption or quality drop of a service | “Something broke; we need to fix it” |
| INC | Nickname / number prefix for that Incident record | People say “the INC” meaning “the ticket” |
| `INC0012345` | Human-readable ticket number | What you paste in chat/Slack |
| `sys_id` | Internal UUID of the same record | What APIs use to update the ticket |

### Example

Dynatrace Problem `P-12345` opens → workflow creates ServiceNow Incident `INC0012345` with `correlation_id = P-12345`.

## INC vs other ServiceNow ticket types (quick)

| Prefix / type | Rough meaning |
| --- | --- |
| INC (Incident) | Something is broken now |
| CHG / CTASK (Change) | Planned change work |
| PRB (Problem, ITIL) | Root-cause / recurring issue analysis |
| RITM / REQ (Request) | Someone asked for something |

Our Dynatrace workflow creates **INC**, not Change or Request.

## Data flow map

```
Dynatrace Problem (monitoring "something wrong")
        │
        ▼
ServiceNow INC (ticket "work this issue")
  number: INC0012345
  correlation_id: P-12345
```

## Related files

| Path | Why |
| --- | --- |
| `../7-what-is-snow-servicenow/` | What SNOW means |
| `../14-explain-demo-flow-plain-english/` | Where INC fits in the demo flow |
| `15.sh` | Reminders |

## Commands

See `15.sh` in this folder.
