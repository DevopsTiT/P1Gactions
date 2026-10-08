# Broker Policy Maintenance Result

| Item | Value |
|---|---|
| Resource | `broker_policy_maintenance_host_count` |
| Threshold | Fewer than 2 pods logging in 60 minutes |
| Severity | medium |
| PagerDuty | "0" |

Before applying, run check query 1 to see whether the pod name is in `k8s.pod.name` or `host.name`. If neither field matches, change the filter to whatever field query 1 shows.
