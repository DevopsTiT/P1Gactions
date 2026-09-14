# Result

Keep ServiceNow and PagerDuty aligned by sharing the Dynatrace Problem ID as correlation keys, creating both on open (then cross-linking), and resolving both on close with those same keys.

| Do | Do not |
| --- | --- |
| Use `correlation_id` = Problem ID | Invent a new random key per run |
| Use `dedup_key` = `dt-problem-<ProblemID>` | Expect SNOW to close PD by itself |
| Run both create and close workflows | Upload only the create workflow |
| Cross-link PD key into INC work notes | Assume humans will remember the mapping |

Optional later: native PagerDuty ↔ ServiceNow integration for assignee/ack mirroring.
