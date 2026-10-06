# Cisco VPN LDAP Picture

## Decision Tree

```
ASA "Windows_LDAP as FAILED" lines
 threshold "3" → copies Splunk → never fired on real data
 threshold "0" → first line alerts → recommended
 no data → check.dql 1 → fix log.source / host
```

## Data Flow

```
ASA → syslog ljcmgt14 → Grail → detector → critical problem → standard flow (page)
```
