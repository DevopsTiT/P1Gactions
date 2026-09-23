# Pic — SILVA HTTP + PD sync

```
No snow connector
  → OPEN:  DT → SILVA HTTP + PD trigger
  → CLOSE: DT → SILVA resolve + PD resolve
  → Sync:  correlation_id == problemId
           dedup_key == dt-problem-<problemId>

Sandbox fail?
  → Allowlist silvastg.service-now.com
  → Allowlist events.pagerduty.com
```
