# Investigation

| Checked | Evidence |
|---|---|
| Alert name | Cisco VPN : LDAP Connections are failing which will impact end users using windows basic |
| Search | index="networksyslog" sourcetype=cisco:asa *Windows_LDAP as FAILED* |
| Schedule | Last 1 minute, every minute |
| Trigger | Results > 3, once, no throttle |
| Actions | Triggered alert Critical, PagerDuty, email |
| Events found | 2 in 30 days (Sep 23 20:46, Sep 24 20:29) |
| Host and source | ljcmgt14.ads-jp.intraxa, /var/log/ASA/JPNDH-VASA19-ALJ.log |
| Message | %ASA-2-113022, one line per LDAP server |
| Secrets | PagerDuty key not visible and not copied |
