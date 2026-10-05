# Investigation

| What was checked | Finding |
|---|---|
| Splunk alert screenshot | Name "Cisco VPN : LDAP Connections are failing which will impact end users using windows basic" |
| Search | `index="networksyslog" sourcetype=cisco:asa *Windows_LDAP as FAILED*` |
| Schedule | Cron every minute, time range last 1 minute |
| Trigger | Number of results greater than 3, once, no throttle |
| Actions | Triggered alert Critical, PagerDuty, send email |
| Source message | Cisco ASA AAA message, usually ASA-2-113022 (LDAP server marked FAILED) |
| Routing | ASA is not a OneAgent host, so the problem has no AGO tags |
