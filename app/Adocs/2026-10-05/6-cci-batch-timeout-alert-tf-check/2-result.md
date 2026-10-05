# Result

| Step | Do this |
|---|---|
| 1 | Remove the PagerDuty integration key from the file; rotate it if it was pushed |
| 2 | Replace `dynatrace_log_alert` with `dynatrace_davis_anomaly_detectors` |
| 3 | Keep the three filters, end the query with `makeTimeseries` |
| 4 | Threshold 0, ABOVE, sliding window 5, violating samples 1, dealerting 5 |
| 5 | Put PagerDuty and the 6 emails in a workflow |
| 6 | Run the DQL check, then `terraform validate` and `plan` |
