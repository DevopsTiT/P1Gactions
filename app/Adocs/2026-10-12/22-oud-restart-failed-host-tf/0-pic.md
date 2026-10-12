# OUD Restart Failed Pic

## Decision tree

```
index=ods sourcetype=oud_service failed
 index=ods → one host → host.name contains WPALJA2162
 sourcetype → check query 2 → add log.source filter if noisy
 last 24h → from:now()-24h
 > 0 → any line
 High + PagerDuty → high, pagerduty 1
```

## Data flow

```
OUD restart on WPALJA2162 → service log → Grail
  → detector (24 h, host + failed) → problem high
  → workflow → PagerDuty + email
```
