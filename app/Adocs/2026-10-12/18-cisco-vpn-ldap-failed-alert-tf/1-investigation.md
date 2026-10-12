# Cisco VPN LDAP Investigation

| What was checked | Finding |
|---|---|
| Source | Splunk Edit Alert screen, not a `.tf` file. |
| Search | `index="networksyslog" sourcetype=cisco:asa *Windows_LDAP as FAILED*` |
| Schedule | Cron every minute, time range last 1 minute. |
| Trigger | Number of results greater than 3, once, for each result. |
| Throttle | Off. |
| Actions | Triggered alert with severity Critical, PagerDuty, send email. |
| Secrets | No key or recipient visible. Nothing copied. |
| Open question | Which Dynatrace field holds the Cisco ASA source. Check query 1 answers it. |
