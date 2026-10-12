# CCI AWS Batch Timeout Alert Format Pic

## Decision tree

```
Is this file a valid Dynatrace alert?
 resource type "dynatrace_log_alert"?
   not in the provider → plan fails → use dynatrace_davis_anomaly_detectors
 query has no time range? → add from:now()-6m
 cron / trigger / throttle? → detector runs every minute; identity field de-duplicates
 PagerDuty integration_key in file? → remove; pagerduty.enabled = "1"; rotate key if committed
 email recipients in file? → move to workflow
```

## Data flow

```
Lambda timeout
  → CloudWatch Logs "Task timed out"
  → Dynatrace Grail logs
  → Records detector (every minute, last 6 minutes)
  → problem (one per log group)
  → workflow → PagerDuty and email
```
