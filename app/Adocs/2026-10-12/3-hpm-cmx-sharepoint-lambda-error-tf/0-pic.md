# HPM CMX To SharePoint Lambda Error Pic

```
dynatrace_log_alert → not in provider → Records detector
 query → same filters + from:now()-60m
 hourly cron + 60m throttle → every-minute detector + aws.log_group identity
 DYNATRACE_PROBLEM MEDIUM → alert.severity medium
 no PagerDuty → pagerduty.enabled "0"
 email → workflow
```

```
Lambda error → CloudWatch Logs → Grail → Records detector (60m) → problem (medium) → workflow → email
```
