# Cisco VPN LDAP Log Source Pic

## Decision tree

```
log.source contains /var/log/ASA + "Windows_LDAP as FAILED"
 window → 5 min
 threshold → none
 identity → log.source
 no data? → fix ASA log ingest
 too noisy? → medium, PagerDuty 0
```

## Data flow

```
ASA → syslog → ljcmgt14 /var/log/ASA/*.log
  → Grail → detector (5 min) → problem high per file
  → PagerDuty + email
```
