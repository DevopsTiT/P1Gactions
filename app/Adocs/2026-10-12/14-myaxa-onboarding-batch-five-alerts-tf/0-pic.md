# MyAXA Onboarding Batch Five Alerts Pic

```
5 x dynatrace_log_alert → 5 x Records detector
 email HIGH, no PagerDuty → severity high, pagerduty.enabled "0"
 Alert 4 = Alert 3 text → likely "message sending failed"
 Alert 5 = Alert 1 text → likely "sendNotificationsQueueConsumer :: error"
 run query 2 → fix → apply
```

```
Lambda logs → CloudWatch → Grail → 5 detectors (5m) → problems (high) → workflow → email
```
