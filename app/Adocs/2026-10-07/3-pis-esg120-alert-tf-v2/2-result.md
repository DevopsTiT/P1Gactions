# Result

| Item | Outcome |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.pis_connection_esg120` |
| Filter | pisp2.log path and "errorCode": "ESG120" |
| Notify | medium, email, pagerduty.enabled 0 |
| Next | check.dql query 2, then `terraform plan` |
