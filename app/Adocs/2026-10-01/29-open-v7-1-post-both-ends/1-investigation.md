# OPEN v7.1 Investigation

| Check | Result |
|---|---|
| Tasks 1 to 3 vs PREVIEW v7.1 | Script text identical (compared with Ruby YAML). |
| Predecessors | 4a and 4b both depend on build-payload only. |
| Script syntax | All five tasks pass node --check. |
| Send settings | DRY_RUN false and ALLOW_SAMPLE_POST false in both send tasks. |
| Maintenance setting | USE_MAINTENANCE_TAG true. |
| Endpoints | SILVA stg POST /api/now/v2/table/incident and PagerDuty /v2/enqueue. |
