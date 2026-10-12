# eopt Pod Error Host Name Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.eopt_openpaas_pod_error_backend` |
| Host filter | starts with eoptsystemapi-, eoptprocessapi- or eoptfrontend- |
| Level | parsed, equals ERROR |
| Window | 1 hour |
| Identity | `service` |
| Severity | medium |
| PagerDuty | off |

## Next steps

| Step | Why |
|---|---|
| Decide on frontend | Remove one line for backend only. |
| Run check queries once logs exist | Confirm hosts and parse. |
| Run `terraform validate` and `plan` from `31.sh` | Confirm the HCL. |
| Apply only one of answers 27, 30, 31 | Same resource name. |
