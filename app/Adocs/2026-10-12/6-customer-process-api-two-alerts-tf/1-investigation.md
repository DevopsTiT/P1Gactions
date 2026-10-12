# Customer Process API Two Alerts Investigation

| Check | Finding |
|---|---|
| Resource type | Both use `dynatrace_log_alert`, which does not exist in the provider. |
| Log group filter | Both use two `contains()` checks; the shorter covers the longer. |
| Alert 1 meaning | Fires on statusCode 201, a successful contract request. |
| Alert 1 statusCode checks | Two forms; the second covers the first. Kept as written. |
| Alert 2 messages | 9 messages OR-ed, all case-insensitive. |
| Alert 2 description | `"Optional"` placeholder. |
| "IBL0250002" | Read from a photo; needs confirming. |
| Schedule | Both every 5 minutes, last 5 minutes, expires 24, no throttle. |
| Actions | Email only, Normal, for both (recipients not copied). No PagerDuty. |
