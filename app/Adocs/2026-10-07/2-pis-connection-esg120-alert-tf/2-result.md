# Result

| Item | Outcome |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.pis_connection_esg120` |
| Logic | Any line with "errorCode": "ESG120" |
| Notify | medium, email (pagerduty.enabled 0 unless Splunk has a PagerDuty action) |
| Next | Check for hidden actions, run check.dql, then `terraform plan` |
