# Result

| Step | Do this |
|---|---|
| 1 | Replace `dynatrace_log_alert` with `dynatrace_davis_anomaly_detectors` |
| 2 | Use `contains(content, "Error", caseSensitive: false)` |
| 3 | Run the grouping query to see what "Error" catches; narrow if noisy |
| 4 | Threshold 0, ABOVE, window 5, violating 1, dealerting 60 |
| 5 | Email from a workflow; keep this medium alert out of PagerDuty |
| 6 | Consider adding `caseSensitive: false` to the earlier converted alerts too |
