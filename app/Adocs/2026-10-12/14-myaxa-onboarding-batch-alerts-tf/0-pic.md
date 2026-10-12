# MyAXA Onboarding Batch Alerts Pic

```
dynatrace_log_alert x 5+ → Records detectors
 Alerts 1-4 → converted (high, pagerduty "0")
 Alert 4 filter = Alert 3 filter → likely "message sending failed"
 Alert 5 → not in photos
 "_High" names, no PagerDuty → confirm paging
```

```
onboarding-batch logs → CloudWatch → Grail → 4 detectors (5m) → problems (high) → workflow → email
```
