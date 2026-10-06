# Result

| Item | Outcome |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.openpaas_egress_proxy_ip_usage` |
| Logic | summarize count, then filter count == 0 |
| Notify | high, email only (pagerduty.enabled 0) |
| Next | Confirm APIGW ingest, then `terraform plan` |
