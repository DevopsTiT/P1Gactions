# Compass BigData Glue Skip Pic

```
dynatrace_log_alert → not in provider → Records detector
 query → same filters + from:now()-5m
 cron */5, expires 2400 → every-minute detector
 email Normal only → alert.severity medium; email in workflow
 no PagerDuty → pagerduty.enabled "0"
```

```
Glue "skipping table" → CloudWatch Logs → Grail → Records detector (5m) → problem (medium) → workflow → email
```
