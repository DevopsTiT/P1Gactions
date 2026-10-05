# HPM SharePoint API Alert Check Pic

```
hpm-sharepoint-api.tf (dynatrace_log_alert → plan fails)
  daily 10:00, last 24h     → scheduled workflow: count + latest 100 → email if > 0
  throttle 60 min           → no effect on daily → drop
  problem MEDIUM            → doesn't fit a daily digest → email only (_Normal)
  status == ERROR or ERROR  → OK, add caseSensitive: false
```
