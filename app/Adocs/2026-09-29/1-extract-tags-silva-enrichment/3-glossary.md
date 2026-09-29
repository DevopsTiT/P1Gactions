# Glossary

| Term | What it means | Why you care |
|---|---|---|
| entity_tags | The tags of the affected entities, sent in the problem event | The main source for routing |
| AGO_ tags | AXA's own tag naming, for example AGO_DEFAULT_ASSIGNMENT_GROUP | These carry the group, trigram, platform and environment |
| Trigram | A 3-letter application code, for example ALJ | Can be mapped to a business service |
| Hint | A tag the workflow recognises by its key name | Feeds the SILVA lookup |
| SAMPLE_EVENT | A built-in test event | Lets you press Run without a real problem |
| sysparm_display_value=all | SILVA returns both the name and the sys_id per field | Produces `assignment_group` and `assignment_group_id` |
| cmdb_ci_service | The SILVA business service table | Source of servicenow_enrichment |
| svc_ci_assoc | The table linking a CI to its business service | Used when there is no service tag |
| BSN number | The number of a business service record, for example BSN0015271 | Shown as `number` |
| Task result | The JSON a workflow task returns | Where you read the output |
