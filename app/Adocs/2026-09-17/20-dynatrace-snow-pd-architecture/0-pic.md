# Pic — Dynatrace SNOW + PD Architecture

```
Detect → Problem
  │
  ├─ OPEN workflow (Connector)
  │     prepare → SNOW INC ‖ PD page → cross-link comment
  │
  ├─ Optional classic notification (ITOM only)
  │
  └─ CLOSE workflow
        search by correlation_id → resolve SNOW ‖ resolve PD
```

```
Same key everywhere
  Problem id → dt-problem-<id>
  → SNOW correlation
  → PD dedup_key
```
