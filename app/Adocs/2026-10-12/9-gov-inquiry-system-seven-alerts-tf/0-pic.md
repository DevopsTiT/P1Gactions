# Gov Inquiry System Seven Alerts Pic

```
7 x dynatrace_log_alert → 7 x Records detector
 Alert 2 unreadable → placeholder, enabled = false
 Summary 1, 2, 3, 7 → low, one problem per file (1, 2, 3) or per log group (7)
 Errors 4, 5, 6     → medium, one problem per log group
 sort and limit → removed
 all → pagerduty.enabled "0", email in workflow
```

```
Lambdas → CloudWatch → Grail → 7 detectors (5m) → problems → workflow → email
```
