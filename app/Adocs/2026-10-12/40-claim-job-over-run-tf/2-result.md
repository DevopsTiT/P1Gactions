# Claim Job Over Run Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.claim_job_over_run` |
| Source | log.source contains daily_ctmag_ |
| Job list | `claims_jobs` array (to fill) |
| Window | 24 hours |
| Condition | STARTED, no ENDED, 15+ minutes |
| Identity | `job_name` |
| Severity | medium |
| PagerDuty | off |

## Next steps

| Step | Why |
|---|---|
| Fill `claims_jobs` from the Splunk lookup | Without it nothing matches. |
| Run check queries 1 to 3 | Confirm logs, parse and open runs. |
| Run check query 4 | Confirm 15 minutes suits each job. |
| Run `terraform validate` and `plan` from `40.sh` | Confirm the HCL. |
