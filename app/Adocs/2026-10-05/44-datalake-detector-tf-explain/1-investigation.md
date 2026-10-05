# Investigation

| Checked | Evidence |
|---|---|
| Setup blocks | `terraform` with dynatrace-oss/dynatrace, empty `provider` |
| Resource | `dynatrace_davis_anomaly_detectors.datalake_batch_result` |
| Analyzer | StaticThresholdAnomalyDetectionAnalyzer |
| Inputs | query, threshold 0, ABOVE, missing data false, violating 1, window 5, dealerting 60 |
| Event properties | CUSTOM_ALERT, name, description, severity low, app.name Datalake, pagerduty.enabled 0 |
