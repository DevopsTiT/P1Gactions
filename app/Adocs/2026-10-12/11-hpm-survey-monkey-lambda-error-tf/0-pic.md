# HPM SurveyMonkey Lambda Error Pic

```
dynatrace_log_alert → Records detector
 query → same filters + from:now()-60m
 hourly cron + 60m throttle → every-minute detector + identity field
 MEDIUM → alert.severity medium
 no PagerDuty → pagerduty.enabled "0"
```

```
Lambda error → CloudWatch Logs → Grail → Records detector (60m) → problem (medium) → workflow → email
```
