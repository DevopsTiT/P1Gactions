# Camunda Error Fatal DQL Pic

## Decision tree

```
3 prefixes (zeebe covers gateway) on host.name or k8s.pod.name
 → uppercase ERROR or FATAL (net effect of match + isnotnull)
 → keywords list → JST time → table
 empty? → check 1 → fix field or onboarding gap
```

## Data flow

```
Camunda 8 pods → Grail ? → prefix filter → ERROR/FATAL → table
```
