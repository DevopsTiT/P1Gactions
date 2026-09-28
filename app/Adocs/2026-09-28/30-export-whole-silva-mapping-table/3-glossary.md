# Glossary

| Term | What it means | Why you care |
|---|---|---|
| CI (configuration item) | A record in the CMDB, such as a host | The workflow sends the host as the CI |
| CMDB | The configuration database in SILVA | This is where hosts and services live |
| svc_ci_assoc | The table that links a CI to a business service | The backbone of the whole table |
| cmdb_rel_ci | The general relationship table between CIs | The fallback if svc_ci_assoc is empty |
| Business service | The application or service a host belongs to | Filled on the incident |
| Service offering | A variant of a business service, usually one per environment | Must match the business service |
| Support group | The team that owns a CI or service | Used as the assignment group |
| Dot-walking | Reading a field through a reference, such as `service_id.name` | Lets one export include columns from linked tables |
| sysparm_limit / sysparm_offset | The API's page size and page start | How you get more than 10,000 rows |
| X-Total-Count | A response header with the total row count | Tells you how many pages you need |
| Display value | The readable name instead of the sys_id | Makes the CSV human-readable |
