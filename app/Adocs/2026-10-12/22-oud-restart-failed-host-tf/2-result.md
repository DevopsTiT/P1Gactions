# OUD Restart Failed Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.oud_restart_failed` |
| Scope | host.name contains WPALJA2162 |
| Window | 24 hours |
| Condition | Any line containing failed |
| Identity | `host.name` |
| Severity | high |
| PagerDuty | on |

## Next steps

| Step | Why |
|---|---|
| Run check query 1 | Confirm the host name in Dynatrace. |
| Run check query 2 | Make sure only the OUD service log matches "failed". |
| Run check query 3 | See how often it would fire. |
| Run `terraform validate` and `plan` from `22.sh` | Confirm the HCL. |
