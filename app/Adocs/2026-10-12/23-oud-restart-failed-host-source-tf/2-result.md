# OUD Restart Failed Host And Source Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.oud_restart_failed` |
| Host filter | host.name contains WPALJA2162 |
| Source filter | starts with `/opt/oracle/oud/`, ends with `/OUD/logs/errors` |
| Window | 24 hours |
| Identity | `log.source` |
| Severity | high |
| PagerDuty | on |

## Next steps

| Step | Why |
|---|---|
| Run the Splunk `stats count by source` | Confirm oud_service is the errors log. |
| Run check query 1 | Confirm Dynatrace uses the same paths. |
| Run check query 2 | See "failed" per file. |
| Run `terraform validate` and `plan` from `23.sh` | Confirm the HCL. |
| Apply only this folder | Same resource name as answer 22. |
