# V7.1 Workflows Pic

```
New result? ─► new numbered folder (old folders untouched)

Import ...-preview-then-post.workflow.yaml
   │
   ▼
Rerun on P-261090
   │
   ├─ cmdb_ci = cfbf255f…        ── no ─► check offering_history in resolve-snow-values
   ├─ u_business_service = 37273dbc… ─ no ─► check method text "replaced by"
   └─ create_incident true       ── no ─► check maintenance tag and missing fields
   │
   ▼
34.sh line 4 ─► incident exists in SILVA stg with cmdb_ci filled
```
