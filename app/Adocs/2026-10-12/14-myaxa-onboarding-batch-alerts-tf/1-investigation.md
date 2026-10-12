# MyAXA Onboarding Batch Alerts Investigation

| Check | Finding |
|---|---|
| Resource type | `dynatrace_log_alert` does not exist in the provider. |
| Alerts visible | 1 to 4. Alert 5 heading only. |
| Alerts 3 and 4 | Read from rotated photos. |
| Alert 4 filter | Reads the same as Alert 3. |
| Alert 2 filters | Second filter redundant. |
| Descriptions | All `"Optional"`. |
| Schedule | All every 5 minutes, last 5 minutes, expires 24, no throttle. |
| Actions | Email only, priority HIGH, 6 recipients (not copied). No PagerDuty. |
