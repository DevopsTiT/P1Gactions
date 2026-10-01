# Full OPEN Workflow Pic

```
problem ──► 1 extract ──► 2 SILVA GET ──► 3 build + decide ──► 4 SILVA POST ──► 5 PagerDuty
                                              │                    │               │
                                              │ create_incident?   │ duplicate?    │ incident existed?
                                              │  no → stop         │  yes → exists │  yes → skip
                                              │                    │  no → created │  no → trigger
```

```
Sync keys
 ├─ SILVA correlation_id = display_id (P-...)
 └─ PagerDuty dedup_key  = dt-problem-<display_id>
```
