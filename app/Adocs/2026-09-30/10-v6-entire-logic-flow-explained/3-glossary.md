# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Davis problem | A Dynatrace problem opened by its AI engine | Starts the workflow |
| status_transition CREATED | The first event of a problem | Stops repeat runs on updates |
| entity_tags | "KEY:value" tags on the affected entity | Main input for group, environment, DB, trigram |
| Candidate | A possible value before it is checked | First checked one wins |
| CI | A CMDB record such as a host or DB | Can link to a business service |
| svc_ci_assoc | SNOW table linking CIs to services | Path B4 |
| cmdb_rel_ci | SNOW relationship table | Path B5 |
| Scored search | Several searches merged and ranked with points | Picks the most likely service |
| First answer | Take the first row of a known-info query | Fallback before the default |
| Default set | Fixed service, group, offering and environment | Used when both service and group are missing |
| snow_form_check | One row per form field with ok, MISSING or empty | Shows gaps |
| correlation_id | SNOW field holding the problem id | Duplicate check and CLOSE |
| dedup_key | PagerDuty key for one problem | Trigger and resolve match |
| DRY_RUN | Build without sending | Safe testing |
