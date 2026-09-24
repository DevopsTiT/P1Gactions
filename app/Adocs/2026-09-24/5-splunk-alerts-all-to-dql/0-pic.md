# Pic — Splunk to DQL batch transfer

```
1 copy.sh alerts (1–16)
  → for each alert:
       index/logGroup → aws.log_group / log.source
       message → content
  → 5-all-splunk-alerts-to-dql.dql
  → validate time range + counts
```
