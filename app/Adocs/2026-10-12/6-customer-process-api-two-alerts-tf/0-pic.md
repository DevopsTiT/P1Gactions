# Customer Process API Two Alerts Pic

```
2 x dynatrace_log_alert → 2 x Records detector
 Alert 1 (statusCode 201, success) → 5m window, severity low
 Alert 2 (9 error messages)        → 5m window, severity medium
 both → pagerduty.enabled "0", email in workflow
```

```
customer-process-api logs → CloudWatch → Grail
  → Alert 1 detector → problem (low)
  → Alert 2 detector → problem (medium)
  → workflow → email
```
