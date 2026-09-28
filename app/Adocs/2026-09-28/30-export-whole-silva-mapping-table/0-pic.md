# Whole Table Export Picture

## Decision tree

```
Want every host → service → offering → group → environment
 ├─ Browser access? → svc_ci_assoc.list → add dot-walked columns → Export CSV
 │    └─ row limit hit? → split with filters, or use the API
 ├─ API → 30.sh lines 1–5 (count, pages, offerings)
 │    ├─ [] or 403 → ask for read access
 │    └─ svc_ci_assoc empty → line 6 (cmdb_rel_ci)
 └─ Join → 30-join-silva-tables.py → silva_whole_table.csv
```

## Data flow

```
cmdb_ci ──► svc_ci_assoc ◄── cmdb_ci_service ──► service_offering
                 │                   │
      silva_ci_service.csv   silva_service_offerings.csv
                 └────────► join script ◄──┘
                                 ▼
                       silva_whole_table.csv ──► SYSTEM_MAP in the OPEN YAML
```
