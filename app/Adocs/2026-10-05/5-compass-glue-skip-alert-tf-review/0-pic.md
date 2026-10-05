# Compass Glue Skip Alert Review Pic

```
dynatrace_log_alert file
  resource exists?            NO → terraform plan error "does not support resource type"
  fields from Splunk screen   → alert_type, cron, trigger_*, throttle, $name$ are not Dynatrace
  DQL filters                 → keep (aws.log_group ==, contains content)
  sort + limit                → replace with makeTimeseries count per 1m

fix
  same schedule idea          → dynatrace_davis_anomaly_detectors (threshold 0, window 5)
  every line alerts           → dynatrace_log_events
  email                       → workflow email task or problem email notification
```
