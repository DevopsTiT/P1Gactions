# EOPT Serverless Two Alerts Pic

```
2 x dynatrace_log_alert → 2 x Records detector
 Alert 1 (5m, filtered fields) → fields timestamp, loglevel, content, aws.log_group
 Alert 2 (daily 10:00, 24h)    → same filter, 24h window; daily digest needs a scheduled workflow
 both "ERROR" case-insensitive → check noise
 both → medium, pagerduty.enabled "0", email in workflow
```

```
eopt-serverless logs → CloudWatch → Grail
  → Alert 1 detector (5m)  → problem
  → Alert 2 detector (24h) → problem
  → workflow → email
```
