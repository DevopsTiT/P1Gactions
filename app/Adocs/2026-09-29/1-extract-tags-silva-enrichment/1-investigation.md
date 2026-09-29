# Investigation

| What was checked | Finding |
|---|---|
| Picture 1 (correctoutput.sh) | Two blocks: `dynatrace_alert` (service_name, alerting_profile, severity, event_name, error_rate) and `servicenow_enrichment` (the business service record fields) |
| Enrichment fields | They are `cmdb_ci_service` fields. Reference fields appear twice (name and `_id`), which matches `sysparm_display_value=all`. |
| Picture 2 (input4.sh event) | Oracle custom device event. Tags have no `[Context]` prefix. There are 13 tags, including `AGO_DEFAULT_ASSIGNMENT_GROUP:Database_AXAJP`, `AGO_AXAOPCOTRIGRAM_ORACLE:ALJ` and `host:deaa310b`. |
| Service name in picture 2 | There are no affected entity names, only the entity id and the entity-type field, so service_name falls back to the id |
| Environment hint | `AGO_AXAPATCHENVIRONMENT_ORACLE:ACCEPTANCE` is the only environment-like tag |
| Requirement | No POST to SNOW and no PagerDuty. SILVA reads (GET) are allowed for the enrichment. |
| Commands run | None |
