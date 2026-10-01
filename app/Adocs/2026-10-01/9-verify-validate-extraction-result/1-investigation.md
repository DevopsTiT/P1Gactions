# Investigation

| What was checked | Evidence |
|---|---|
| payload_preview | caller_id and u_on_behalf_of = "Dynatrace JP" |
| reference_incident fields | caller_id reference_value 8ddef691fb34cf547b0dfe7b4eefdcbc, same_value false |
| business_service vs service_offering | Both 02a238ce1b877c54688064e4604bcbf9 |
| Choice lists | impact, urgency, category, subcategory, contact_type, u_environment all [] |
| Description tags | AGO_AXAPATCHENVIRONMENT_ORACLE:ACCEPTANCE, AGO_ORACLE_ASSIGNMENT_GROUP:Database_AXAJP |
| Workflow code | cmdb_ci_service searches had no class filter; service_offering extends cmdb_ci_service |
| Workflow code | CALLER_SYS_ID and ON_BEHALF_OF_SYS_ID were empty, so names were sent |
| Mapping | acceptance → "Integration / Test" in envLabel map (line ~78) |
