# Datalake Batch Result Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.datalake_batch_result` |
| Hosts | CEAA20BD, CEAA20BE, CEAA2101 |
| Source | contains datalake_transfer.log |
| Window | Last 8 hours |
| Timing | JST 08:00 to 08:04 |
| Identity | `host.name` |
| Severity | low |
| PagerDuty | off |

## Next steps

| Step | Why |
|---|---|
| Run check query 1 | Confirm logs exist and get the exact source path. |
| Decide report or alert | A failure-only filter (check query 3) is a better alert. |
| Run `terraform validate` and `plan` from `38.sh` | Confirm the HCL. |
