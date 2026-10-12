# Cisco VPN LDAP Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.cisco_vpn_ldap_connections_failing` |
| Window | 1 minute |
| Condition | More than 3 matching lines |
| Identity | `scope` |
| Severity | high |
| PagerDuty | on |

## Next steps

| Step | Why |
|---|---|
| Run check query 1 | Find the source field and optionally add it as a filter. |
| Run check query 2 | Confirm 3 per minute is a sensible threshold. |
| Run `terraform validate` and `plan` from `18.sh` | Confirm the HCL before applying. |
