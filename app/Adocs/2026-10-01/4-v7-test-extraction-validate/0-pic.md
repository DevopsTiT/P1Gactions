# Test Workflow Picture

```
verdict?
 ├─ PASS               → copy settings into OPEN
 ├─ PASS WITH WARNINGS → read WARN rows
 └─ FAIL               → read FAIL rows
      ├─ group ≠ enrichment         → GROUP_ORDER
      ├─ offering parent wrong      → offering_candidates
      ├─ u_environment not valid    → valid_choices → PREPROD_LABEL / ENV_VALUE
      └─ caller is a name           → CALLER_SYS_ID
```

```
event → 1 extract → 2 resolve (SILVA GET) → 3 build-payload (preview) → 4 validate (SILVA GET)
                                    group = tag > servicenow_enrichment > CI > default
NO POST · NO PATCH · NO PagerDuty
```
