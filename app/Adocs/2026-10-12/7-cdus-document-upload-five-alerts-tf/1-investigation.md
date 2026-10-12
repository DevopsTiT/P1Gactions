# CDUS Document Upload Five Alerts Investigation

| Check | Finding |
|---|---|
| Resource type | All five use `dynatrace_log_alert`, which does not exist in the provider. |
| Schedule | All every 5 minutes, last 15 minutes, expires 30. |
| Actions | All: problem HIGH, PagerDuty (same key, not copied), email to 2 lists (not copied). |
| Alert 1 vs Alert 5 | Identical queries. |
| Alert 1 name | "Pending Uploads", but the filter finds crash messages. |
| Alert 2 filter | "action:" and "cmxDocumentId:" may be normal log fields. |
| Alert 3 filter | "ETIM" case-insensitive can match "dateTime" and "lifetime". |
| Alert 5 throttle | 8 hours; no exact detector equivalent. |
