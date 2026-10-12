# PMT API Nine Alerts Investigation

| Check | Finding |
|---|---|
| Resource type | All nine use `dynatrace_log_alert`, which does not exist in the provider. |
| Log group filter | Two `contains()` checks in each; the shorter covers the longer. |
| Alert 2 parse | `LD:MemoryUsage` captures the rest of the line; `toLong()` returns null; never fires. |
| Alerts 6 and 7 | Identical queries. |
| Alert 9 | Filter spelled "occured"; title spelled "occurred". |
| Alert 3 | "Task timed out" is not specific to transformation. |
| Throttles | 60 seconds on Alerts 4, 6, 7, 8, 9. |
| Actions | Email Normal (1-5, 8, 9; not copied) or problem MEDIUM (6, 7). No PagerDuty. |
| Descriptions | "Optional" placeholder on all except Alert 7. |
