# Application Monitoring URL Result

| Item | Value |
|---|---|
| Resource | `application_monitoring_alert_url` |
| Rule | 2 or more non-200 results and no 200 in 15 minutes, per job |
| Severity | high |
| PagerDuty | "0" (Disable confirmed) |

Before applying, run check query 1 to confirm the `status=` format, and query 2 to confirm each job runs at least twice in 15 minutes.
