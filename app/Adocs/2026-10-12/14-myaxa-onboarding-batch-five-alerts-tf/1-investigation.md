# MyAXA Onboarding Batch Five Alerts Investigation

| Check | Finding |
|---|---|
| Resource type | All five use `dynatrace_log_alert`, which does not exist in the provider. |
| Log group filter | Two `contains()` checks in each; the shorter covers the longer. |
| Alert 2 | Second content filter is covered by the first. |
| Alert 4 | Same text as Alert 3, though titled "message sending failed". |
| Alert 5 | Same text as Alert 1, though titled "QueueConsumer error". |
| Photos | Alerts 3 to 5 were read from rotated photos. |
| Description | "Optional" placeholder in all five. |
| Actions | Email only, priority HIGH, 6 recipients (not copied). No PagerDuty. |
