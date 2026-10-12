# eopt OpenPaaS Pod Error Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.eopt_openpaas_pod_error_backend` |
| Pod filter | starts with eoptsystemapi- or eoptprocessapi- |
| Level | parsed, equals ERROR |
| Window | 1 hour |
| Identity | `service` |
| Severity | medium |
| PagerDuty | off |

## Next steps

| Step | Why |
|---|---|
| Run check queries 1 and 2 | Confirm pod field and parse. |
| Run check query 4 | Decide on frontend pods. |
| Run `terraform validate` and `plan` from `27.sh` | Confirm the HCL. |
