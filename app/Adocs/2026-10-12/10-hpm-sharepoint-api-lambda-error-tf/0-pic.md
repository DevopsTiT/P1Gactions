# HPM SharePoint API Lambda Error Pic

```
dynatrace_log_alert → Records detector
 query → same filters + from:now()-24h
 daily 10:00 → not possible; detector every minute (or scheduled workflow)
 throttle 60m → identity field
 MEDIUM → alert.severity medium
 no PagerDuty → pagerduty.enabled "0"
```

```
Lambda error → CloudWatch Logs → Grail → Records detector (24h) → problem (medium) → workflow → email
```
