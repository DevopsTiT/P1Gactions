# eopt Backend Hosts Only Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.eopt_openpaas_pod_error_backend` |
| Host filter | starts with eoptsystemapi- or eoptprocessapi- |
| Level | parsed, equals ERROR |
| Window | 1 hour |
| Identity | `service` |
| Severity | medium |
| PagerDuty | off |

## Next steps

| Step | Why |
|---|---|
| Apply answers 32 and 33 together | Frontend and backend covered once each. |
| Run `terraform validate` and `plan` from `33.sh` | Confirm the HCL. |
