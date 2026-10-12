# Cisco VPN LDAP Per Server Pic

## Decision tree

```
2 events per month, one line per LDAP server
 old rule > 3 per minute → never fires
 new rule → any ASA-2-113022 Windows_LDAP FAILED line → problem per server
 no lines in Dynatrace? → fix ASA syslog ingest first
 too noisy for one server? → medium, PagerDuty 0
```

## Data flow

```
ASA marks LDAP server FAILED → syslog → ljcmgt14
  → Grail logs → detector (5 min, parse ldap_server)
  → problem high per server → PagerDuty + email
```
