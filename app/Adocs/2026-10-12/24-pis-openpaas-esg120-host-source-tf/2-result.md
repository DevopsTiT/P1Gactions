# PIS OpenPaaS ESG120 Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.pis_connection_issue_batch_openpaas` |
| Host filter | host.name contains CEAA20B8 |
| Source filter | log.source contains /IFDATA/DATA/PC/LOG/PISP2/pisp2.log |
| Content filter | errorCode and ESG120 |
| Window | 5 minutes |
| Identity | `log.source` |
| Severity | medium |
| PagerDuty | off |

## Next steps

| Step | Why |
|---|---|
| Run check query 1 | Confirm host spelling and source path. |
| Run check query 2 | Expect about 18 events. |
| Run `terraform validate` and `plan` from `24.sh` | Confirm the HCL. |
