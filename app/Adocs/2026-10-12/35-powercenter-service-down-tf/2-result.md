# PowerCenter Service Down Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.mwsp_powercenter_service_down` |
| Filter | content contains ISP_MASTER_ELECT_LOCK |
| Window | 1 minute |
| Condition | More than 2 lines |
| Identity | `scope` |
| Severity | medium |
| PagerDuty | off |

## Next steps

| Step | Why |
|---|---|
| Run check query 3 | Confirm PowerCenter logs are in Dynatrace. |
| Run check query 1 | Find the host to add as a filter. |
| Run check query 2 | Confirm the threshold. |
| Run `terraform validate` and `plan` from `35.sh` | Confirm the HCL. |
