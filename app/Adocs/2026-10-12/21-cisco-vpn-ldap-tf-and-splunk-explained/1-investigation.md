# Cisco VPN LDAP Explained Investigation

| What was read | Value |
|---|---|
| Alert name | Cisco VPN : LDAP Connections are failing which will impact end users using windows basic |
| Search | `index="networksyslog" sourcetype=cisco:asa *Windows_LDAP as FAILED*` |
| Alert type | Scheduled, cron `*/1 * * * *` |
| Time range | Last 1 minute |
| Expires | 24 hours |
| Trigger rule | Number of results greater than 3 |
| Throttle | Off |
| Actions | Triggered alert Critical, PagerDuty, send email |
| Earlier Splunk search | 2 matching events in one month, one per LDAP server |
| Terraform explained | Answer 20, `20-cisco-vpn-ldap-logsource-tf.tf` |
