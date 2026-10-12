# Gov Inquiry System Seven Alerts Investigation

| Check | Finding |
|---|---|
| Resource type | All seven use `dynatrace_log_alert`, which does not exist in the provider. |
| Alert 1 | Read clearly from a straight photo. |
| Alert 2 | Name and description readable; query unreadable (rotated, blurry). |
| Alert 3 | Read from a rotated photo; log group and fileCategory need confirming. |
| Alert 4 | Read from a rotated photo; log group needs confirming. |
| Alerts 5 to 7 | Read clearly. |
| Queries 3 to 7 | Include `sort timestamp desc` and `limit 100`, not needed in a detector. |
| Parse | `WORD:fileName` may cut file names at "." and "-". |
| Schedule | All every 5 minutes, last 5 minutes, expires 24, no throttle. |
| Actions | Email only, Normal, one distribution list (not copied). No PagerDuty. |
