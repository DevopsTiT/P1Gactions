# Pic — Two YAML detail map

```
OPEN YAML                         CLOSE YAML
─────────                         ──────────
trigger: Problem ACTIVE           trigger: Problem CLOSED
prepare-payload                   prepare-close-ids
   │                                 │
   ├─ SILVA POST create              ├─ SILVA GET+PATCH resolve
   └─ PD trigger                     └─ PD resolve

Shared sync:
  correlation_id = problemId
  dedup_key = dt-problem-<problemId>
```
