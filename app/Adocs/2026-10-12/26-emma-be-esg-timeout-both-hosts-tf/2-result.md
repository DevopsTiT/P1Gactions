# Emma BE ESG Timeout Both Hosts Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.emma_be_timeout_to_esg_production` |
| Backend filter | host or pod starts with myaxabackend- |
| Gateway filter | host contains EEAA2015, source contains /SYSLOG/APIGW/prod/local4.log |
| Window | 5 minutes |
| Condition | More than 20 timeouts in total |
| Identity | `scope` |
| Severity | high |
| PagerDuty | on |

## Next steps

| Step | Why |
|---|---|
| Run check queries 1 and 2 | Confirm host and pod fields. |
| Run check query 4 | Confirm the threshold. |
| Run `terraform validate` and `plan` from `26.sh` | Confirm the HCL. |
| Apply only this folder | Same resource name as answer 25. |
