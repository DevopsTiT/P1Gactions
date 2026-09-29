# Investigation

| What was checked | Finding |
|---|---|
| Picture 5 (correctoutput.sh) | Two blocks: dynatrace_alert with 5 fields, servicenow_enrichment with 17 fields |
| v3 display-result script | Returns 7 blocks: dynatrace_alert, servicenow_enrichment, decision, snow_incident_payload, pagerduty_payload, tags, lookup |
| Extra alert fields in v3 | problem_id, problem_url, impact_level, host, entity_id, entity_type, environment, environment_tag, db_type, trigram, platform, region, maintenance |
| Extra enrichment fields in v3 | found, match_method, service_offering(_id), configuration_item(_id, _class, _fqdn), ci_support_group(_id) |
| Sync keys | problem_id feeds the SNOW correlation_id and the PD dedup_key |
| User feedback | "the result is fine" |
| Commands run | None |
