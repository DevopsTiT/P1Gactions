# Cisco VPN LDAP Per Server Result

| Setting | Value |
|---|---|
| Resource | `dynatrace_davis_anomaly_detectors.cisco_vpn_ldap_connections_failing` |
| Window | 5 minutes |
| Condition | Any matching line |
| Identity | `ldap_server` |
| Severity | high |
| PagerDuty | on |

## Next steps

| Step | Why |
|---|---|
| Run check query 1 | Confirm the ASA lines are in Dynatrace. |
| Run check query 3 | Confirm the parse returns the server IP. |
| Decide paging for one server | One of two failed may not need a page. |
| Run `terraform validate` and `plan` from `19.sh` | Confirm the HCL. |
| Do not also apply answer 18 | Same resource name. |
