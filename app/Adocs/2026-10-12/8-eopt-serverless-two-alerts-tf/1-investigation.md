# EOPT Serverless Two Alerts Investigation

| Check | Finding |
|---|---|
| Resource type | Both use `dynatrace_log_alert`, which does not exist in the provider. |
| Log group filter | Two `contains()` checks in each; the shorter covers the longer. |
| Content filter | Both "ERROR", case-insensitive. |
| Alert 1 output | "Filtered fields: timestamp, level, message". |
| Alert 2 schedule | Daily 10:00 over 24 hours; same filter as Alert 1. |
| Actions | Email only, Normal, for both (recipients not copied). No PagerDuty. |
