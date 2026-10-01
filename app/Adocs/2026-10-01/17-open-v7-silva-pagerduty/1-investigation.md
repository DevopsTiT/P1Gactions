# Investigation

| What was checked | Evidence |
|---|---|
| TEST v7 tasks 1 to 3 | Contain all fixes (group order, env, caller sys_id, offering exclusion, final keys) |
| OPEN v6 tasks 4 and 5 | Duplicate check, POST, PD trigger with dedup_key dt-problem-<id> |
| Missing in TEST build-payload | decision, pagerduty_payload, used_sample_event; added |
| Keys | Confirmed on INC30340215: u_business_service, cmdb_ci, u_configuration_item |
| Lint | No linter errors in the new YAML |
