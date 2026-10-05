# Investigation

| What was checked | Finding |
|---|---|
| Alert A | `index=network* sourcetype=asa_networksyslog *Windows_LDAP as FAILED*` |
| Alert B | `index="networksyslog" sourcetype=cisco:asa *Windows_LDAP as FAILED*` |
| Shared settings | Cron every minute, last 1 minute, more than 3 results, once, no throttle |
| Actions | Triggered alert Critical, PagerDuty, Send email |
| Overlap | `network*` includes `networksyslog`, so both can fire for one outage |
| Standard flow | Group from entity tags only; a log-based custom alert has none |
