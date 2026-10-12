# Recruitimp Serverless Two Alerts Pic

```
2 x dynatrace_log_alert → 2 x Records detector
 Alert 1 (daily 08:00, 24h, level:ERROR) → 24h window; daily digest needs a scheduled workflow
 Alert 2 (5m, "ERROR" anywhere)          → 5m window; overlaps Alert 1; check noise
 both → medium, pagerduty.enabled "0", email in workflow
```

```
recruitimp-serverless logs → CloudWatch → Grail
  → Alert 1 detector (24h) → problem
  → Alert 2 detector (5m)  → problem
  → workflow → email
```
