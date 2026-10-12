# Cisco VPN LDAP Log Source Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.cisco_vpn_ldap_connections_failing` |
| Window | 5 minutes |
| Condition | Any matching line |
| Identity | `log.source` |
| Severity | high |
| PagerDuty | on |

## Next steps

| Step | Why |
|---|---|
| Run check query 1 | Confirm the four ASA files are in Dynatrace. |
| Run check query 2 | Expect the same 2 events Splunk found. |
| Run `terraform validate` and `plan` from `20.sh` | Confirm the HCL. |
| Apply only this folder | Answers 18 and 19 use the same resource name. |
