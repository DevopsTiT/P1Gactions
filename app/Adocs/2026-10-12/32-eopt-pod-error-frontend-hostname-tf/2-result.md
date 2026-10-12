# eopt Pod Error Frontend Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.eopt_openpaas_pod_error_frontend` |
| Host filter | starts with eoptfrontend- |
| Level | JSON key level, upper case, equals ERROR |
| Window | 1 hour |
| Identity | `service` |
| Severity | medium |
| PagerDuty | off |

## Next steps

| Step | Why |
|---|---|
| Remove the eoptfrontend- line from answer 31 | Keep backend and frontend separate. |
| Run check query 1 once logs exist | Confirm JSON parse and levels. |
| Run `terraform validate` and `plan` from `32.sh` | Confirm the HCL. |
