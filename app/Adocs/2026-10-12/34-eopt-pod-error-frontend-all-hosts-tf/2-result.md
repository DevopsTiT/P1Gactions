# eopt Frontend All Hosts Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.eopt_openpaas_pod_error_frontend` |
| Host filter | starts with eoptsystemapi-, eoptprocessapi- or eoptfrontend- |
| Level | JSON key level, upper case, equals ERROR |
| Window | 1 hour |
| Identity | `service` |
| Severity | medium |
| PagerDuty | off |

## Next steps

| Step | Why |
|---|---|
| Apply answers 31 and 34 | Both alerts with the same host filter. |
| Run check query 1 once logs exist | See which services write JSON. |
| Run `terraform validate` and `plan` from `34.sh` | Confirm the HCL. |
