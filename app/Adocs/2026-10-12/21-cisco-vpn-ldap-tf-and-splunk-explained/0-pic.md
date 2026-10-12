# Cisco VPN LDAP Explained Pic

## Decision tree

```
Splunk screen                        Terraform
 Alert, Description          →  title, description
 Search                      →  log.source + content filters
 Last 1 minute               →  from:now()-5m
 Cron every minute           →  built in
 Expires 24h                 →  not needed
 Results > 3                 →  removed (any line)
 Once / For each result      →  identity log.source
 Critical                    →  high
 PagerDuty + email           →  workflow
```

## Data flow

```
OLD: ASA → Splunk → 1 min search → > 3 lines → page (never fired)
NEW: ASA → Grail → 5 min detector → any line → problem high → workflow → page + email
```
