# Recruitimp Serverless Two Alerts Investigation

| Check | Finding |
|---|---|
| Resource type | Both use `dynatrace_log_alert`, which does not exist in the provider. |
| Log group filter | Two `contains()` checks in each; the shorter covers the longer. |
| Alert 1 content | "level:ERROR" or "level:error", both case-insensitive (redundant). |
| Alert 1 schedule | Daily 08:00 over 24 hours. |
| Alert 2 content | "ERROR" anywhere, case-insensitive. |
| Overlap | Every Alert 1 line also matches Alert 2. |
| Descriptions | "Optional" placeholder in both. |
| Actions | Email only, Normal (recipients not copied). No PagerDuty. |
