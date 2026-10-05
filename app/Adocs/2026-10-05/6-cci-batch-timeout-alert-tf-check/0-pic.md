# CCI Batch Timeout Alert Check Pic

```
cci-fa-comm-calc.tf
  dynatrace_log_alert?          → does not exist → plan fails
  integration_key on line 32?   → secret in code → remove, rotate if pushed
  filters (log group, "Task timed out", not "!DEBUG!") → keep
  sort + limit                  → makeTimeseries count per 1m
  */5, last 6 min, > 0, once    → window 5, threshold 0 ABOVE, violating 1
  PagerDuty + 6 emails          → workflow tasks
```
