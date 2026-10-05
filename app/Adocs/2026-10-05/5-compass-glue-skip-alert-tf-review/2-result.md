# Result

| Step | Do this |
|---|---|
| 1 | Do not use `dynatrace_log_alert` as a template |
| 2 | Use `dynatrace_davis_anomaly_detectors` with threshold 0, ABOVE, sliding window 5, violating samples 1 |
| 3 | Or use `dynatrace_log_events` for per-line alerts |
| 4 | Change `contains(aws.log_group, ...)` to `aws.log_group == ...` for the exact group |
| 5 | Set up email via a workflow or problem email notification |
| 6 | Run `terraform validate` and `terraform plan` before merging |
