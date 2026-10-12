# Control-M Abend Alert V2 Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.ctlm_abend_alert_v2` |
| Filter | content contains Ended not OK |
| Window | 5 minutes |
| Identity | `JOB_CODE` |
| Severity | high |
| PagerDuty | off until actions are confirmed |

## Next steps

| Step | Why |
|---|---|
| Run check query 1 and 3 | Confirm the line format and the parse. |
| Run check query 2 | Add a source filter. |
| Check Splunk actions | Decide PagerDuty. |
| Run `terraform validate` and `plan` from `39.sh` | Confirm the HCL. |
