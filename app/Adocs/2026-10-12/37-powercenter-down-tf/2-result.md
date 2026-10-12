# Powercenter Down Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.powercenter_down` |
| Filter | content contains ISP_MASTER_ELECT_LOCK |
| Window | 1 minute |
| Condition | More than 3 lines |
| Identity | `scope` |
| Severity | medium |
| PagerDuty | off |

## Next steps

| Step | Why |
|---|---|
| Run check query 1 | Find the host to add as a filter. |
| Run check query 2 | Confirm the threshold. |
| Decide on answers 35, 36 and 37 | Same search, three problems per incident. |
| Run `terraform validate` and `plan` from `37.sh` | Confirm the HCL. |
