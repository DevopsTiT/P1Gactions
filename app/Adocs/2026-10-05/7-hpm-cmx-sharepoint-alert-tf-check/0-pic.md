# HPM CMX SharePoint Alert Check Pic

```
cmx-sharepoint-api.tf
  dynatrace_log_alert?           → does not exist → plan fails
  contains "Error"               → case-sensitive in DQL → add caseSensitive: false
  hourly, 60 min, throttle 60    → checks every minute, dealertingSamples 60
  DYNATRACE_PROBLEM MEDIUM       → detector opens problem, alert.severity medium
  "_Normal"                      → no PagerDuty page; email only
```
