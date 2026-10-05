# Cisco VPN LDAP Two Alerts Pic

```
Splunk A (network*, asa_networksyslog) + Splunk B (networksyslog, cisco:asa)
  same "Windows_LDAP as FAILED" → double paging today
  → 1 detector: bucket network*, dedup, count > 3 per minute, critical
  → standard SILVA + PagerDuty flow (needs routing: no AGO tags on a log alert)
  → email workflow (recipients to fill in)
```
