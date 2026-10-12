# Cisco VPN LDAP Pic

## Decision tree

```
Splunk: *Windows_LDAP as FAILED*, last 1 min, > 3 results, Critical, PagerDuty
 index and sourcetype → no Dynatrace match → content filter (optional log.source)
 > 3 → summarize count() → filter failures > 3
 Critical → high → pagerduty.enabled 1
 noisy? → check query 2 → raise threshold
```

## Data flow

```
Cisco ASA → syslog "Windows_LDAP as FAILED"
  → Grail logs
  → detector (1 min count > 3) → problem high
  → workflow → PagerDuty + email
```
