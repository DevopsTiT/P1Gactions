# PowerCenter Process Stop Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.powercenter_process_stop` |
| Filter | content contains ISP_MASTER_ELECT_LOCK |
| Window | 15 minutes |
| Condition | Any line |
| Identity | `host.name` |
| Severity | high |
| PagerDuty | off |

## Next steps

| Step | Why |
|---|---|
| Run check query 1 | Find the host to add as a filter. |
| Run check query 2 | See how noisy it will be. |
| Decide on answer 35 | Same search. Keeping both doubles problems. |
| Run `terraform validate` and `plan` from `36.sh` | Confirm the HCL. |
