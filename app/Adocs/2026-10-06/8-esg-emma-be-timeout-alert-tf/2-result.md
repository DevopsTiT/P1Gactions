# Result

| Item | Outcome |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.esg_emma_be_timeout` |
| Logic | Two sources with or, summarize count, filter count > 20 |
| Notify | high, email only (pagerduty.enabled 0) |
| Next | Confirm backend log labels, then `terraform plan` |
