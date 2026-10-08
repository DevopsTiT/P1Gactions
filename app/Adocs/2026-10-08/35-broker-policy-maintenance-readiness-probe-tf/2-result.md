# Readiness Probe Result

| Item | Value |
|---|---|
| Resource | `broker_policy_maintenance_readiness_probe` |
| Logic | Per pod, newest health status in 5 minutes is not 200 |
| Severity | medium |
| PagerDuty | "0" |

Before applying, run check query 1. If statusCode is missing, do not apply yet. The detector would never fire, just like the Splunk alert.
