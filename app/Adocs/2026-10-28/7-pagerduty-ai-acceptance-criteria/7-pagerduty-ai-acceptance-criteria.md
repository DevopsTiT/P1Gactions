# PagerDuty AI Acceptance Criteria

```
Need the section 8 paste again?
  test service only → do not page production
  Teams connected → a reply appears in the channel
  five test incidents → reviewer matches id and state to PagerDuty
  status stays a draft until a person sends it
  assist down → the page and escalation policy still run
  no accuracy percentage on this form
```

| Key point | Detail |
|---|---|
| Box | Business Requirements (4/4), section 8. |
| Kind of test | A checked reply on test incidents. This is not a document-accuracy test. |
| Pass mark | A Technology DevOps reviewer can match the reply to the PagerDuty incident. |

## Summary

The tool is accepted when a linked person gets a reply in Microsoft Teams on a test incident, a reviewer agrees that reply matches PagerDuty on five agreed incidents, a person still sends any status, and paging still works when the assist is unavailable.

## Investigation

| Source | What it shows |
|---|---|
| Section 8 on the slide | Asks for acceptance criteria and what success means. The printed examples are document accuracy and a knowledge-library chat. |
| This use case | PagerDuty AI in Microsoft Teams after a test incident exists. |
| Page 3 | A person confirms the reply before they act. |
| Page 4 downtime | The assist can be down without stopping the call, SMS, or escalation policy. |

## Result

Paste the block below into section 8.

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

## Data flow map

```
[Test PagerDuty incident]
        |
        v
[Teams question] → [AI reply]
        |
        +-- reviewer matches id and state to PagerDuty
        |
        +-- person sends status only after reading the draft
        |
        v
pass on five agreed incidents

[Assist unavailable]
        |
        v
[PagerDuty] still creates the incident and runs the escalation policy
```

## Related files

| File | Role |
|---|---|
| `Daily Files/2026-10-28/6-pagerduty-ai-gate0-page4/` | Full page 4, including stakeholders and the 4-hour downtime. |
| `7.sh` | Copy and git one-liners. Review before running. |

## Commands

See [7.sh](7.sh). Do not commit or push until you ask for that.
