# CSDDM Two Alerts Investigation

| Check | Finding |
|---|---|
| Resource type | Both use `dynatrace_log_alert`, which does not exist in the provider. |
| Alert 1 description | `"Optional"` placeholder. |
| Alert 1 log group | Two `contains()` checks; the shorter covers the longer and also the -prod group. |
| Alert 1 schedule | Daily 10:00 over 24 hours. A detector cannot keep that schedule. |
| Alert 2 query | Includes `sort` and `limit 100`, not needed in a detector. |
| Alert 2 case | `contains(content, "error")` without `caseSensitive:false`. |
| Alert 2 throttle | 1 hour. |
| Actions | Email only, Normal, for both (recipients not copied). No PagerDuty. |
