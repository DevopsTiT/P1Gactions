# cmdb_ci Investigation

| Evidence | Finding |
|---|---|
| build-payload missing | cmdb_ci (Service Offering). |
| servicenow_enrichment | Distr-Windows-OS-JumpServer-AGO, BSN0186416, Technology Management Service, owner DISTR_WINDOWS_OS_ENGINEERING. |
| match_method | CI ts12.hk.intraxa -> cmdb_rel_ci (Depends on::Used by). No switch, so no other linked service had offerings. |
| INC30340215 (seq 16) | Same host CI 1dfdcf8a…, offering cfbf255f…, business service 37273dbc…. |
| Change | History fallback added to task 2 in seq 30, 29, 23, 17, 4. |
| Check | All five YAMLs parse, all scripts pass node --check, tasks 1 to 3 identical across 23, 29, 30, 17. |
