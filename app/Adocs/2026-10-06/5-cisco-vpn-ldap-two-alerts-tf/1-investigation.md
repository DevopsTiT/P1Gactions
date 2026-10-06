# Investigation

| Checked | Finding |
|---|---|
| Alert 1 search | index=*network* sourcetype=asa_networksyslog *Windows_LDAP as FAILED* |
| Alert 2 search | index="networksyslog" sourcetype=cisco:asa *Windows_LDAP as FAILED* |
| Schedule | Both: Last 1 minute, */1, expires 24 hours |
| Trigger | Both: results > 3, Once, For each result, no throttle |
| Actions | Both: Critical, PagerDuty, email |
