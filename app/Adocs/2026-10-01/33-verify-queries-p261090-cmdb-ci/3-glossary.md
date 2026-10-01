# Glossary

| Term | What it means |
|---|---|
| `cmdb_ci` (on incident) | In SILVA this holds the Service Offering, not the server. |
| `u_configuration_item` | The host CI (the server, here ts12.hk.intraxa). |
| `u_business_service` | The business service, the parent of the offering. |
| Service Offering | A specific flavor of a business service, often one per environment. |
| `sysparm_query` | The ServiceNow filter. `^` means AND, `^OR` means OR. |
| `ISNOTEMPTY` | Only rows where the field has a value. |
| `ORDERBYDESC` | Sort newest first. |
| `correlation_id` | Field on the incident holding the Dynatrace problem id. Used to find duplicates. |
| Technology Management Service | A technical service with no offerings, so it cannot fill cmdb_ci. |
| SERVICE_MAP | Manual mapping in the workflow when CMDB data cannot lead to the offering. |
