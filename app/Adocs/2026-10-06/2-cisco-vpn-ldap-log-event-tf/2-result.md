# Result

| Item | Outcome |
|---|---|
| Resource | `dynatrace_log_events.cisco_vpn_ldap_failed` |
| Matcher | log.source /var/log/ASA/* and phrase "Windows_LDAP as FAILED" |
| Severity | critical, pages through the standard flow |
| Next | Run check.dql, then `terraform plan` |
