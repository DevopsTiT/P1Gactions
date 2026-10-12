# OUD Restart Failed Host And Source Pic

## Decision tree

```
host WPALJA2162
 source /opt/oracle/oud/*/OUD/logs/
   access → skip (normal login failures)
   errors → keep (restart failures)
 unsure? → Splunk stats count by source for sourcetype=oud_service
 identity → log.source
```

## Data flow

```
OUD errors logs (asinst_1, asinst_2) → Grail
  → detector (24 h, failed) → problem high per file
  → workflow → PagerDuty + email
```
