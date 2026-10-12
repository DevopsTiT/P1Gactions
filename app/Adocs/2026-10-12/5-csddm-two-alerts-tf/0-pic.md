# CSDDM Two Alerts Pic

```
2 x dynatrace_log_alert → 2 x Records detector
 Alert 1 (daily 10:00, 24h) → every minute over 24h; daily email needs a scheduled workflow
 Alert 2 (5m, throttle 1h) → every minute over 5m; sort and limit removed; "error" case-sensitive
 both → medium, pagerduty.enabled "0", email in workflow
```

```
Lambda error → CloudWatch Logs → Grail
  → Alert 1 detector (24h, all groups) → problem
  → Alert 2 detector (5m, -prod)       → problem
  → workflow → email
```
