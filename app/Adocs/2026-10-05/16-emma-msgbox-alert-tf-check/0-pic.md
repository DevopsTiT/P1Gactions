# Emma MsgBox Alert Check Pic

```
message-box-api.tf (dynatrace_log_alert → plan fails)
  "error" / "warn" lowercase → caseSensitive: false
  > 5 in 5 min               → makeTimeseries 1m + arrayMovingSum(count, 5), threshold 5
  no throttle                → dealerting 5
  problem MEDIUM             → alert.severity medium
  email Teams + 2            → email workflow, no PagerDuty
  noisy "warn"?              → noise-check.dql first
```
