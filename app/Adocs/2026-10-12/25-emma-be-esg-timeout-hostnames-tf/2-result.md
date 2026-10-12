# Emma BE ESG Timeout Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.emma_be_timeout_to_esg_production` |
| Host filter | host.name or k8s.pod.name starts with myaxabackend- |
| Window | 5 minutes |
| Condition | More than 20 timeouts, both parts together |
| Identity | `scope` |
| Severity | high |
| PagerDuty | on |

## Next steps

| Step | Why |
|---|---|
| Run check query 1 | Find the field holding the pod names. |
| Run check query 4 | See if more than 20 in 5 minutes ever happened. |
| Run `terraform validate` and `plan` from `25.sh` | Confirm the HCL. |
