# InnoRules BRE Alert Pic

```
dynatrace_log_alert → Records detector
 cron */5 1-5 → hour filter on log timestamp (UTC; JST version available)
 PagerDuty only → pagerduty.enabled "1", severity high
 key in old file → removed; rotate if committed
```

```
InnoRules ERROR → CloudWatch → Grail → detector (5m, hours 1-5) → problem (high) → workflow → PagerDuty
```
