# Glossary

| Term | What it means |
|---|---|
| `cmdb_ci` (on incident) | In SILVA this holds the Service Offering, not the server. |
| `u_configuration_item` | The host CI, here ts12.hk.intraxa. |
| `u_business_service` | The business service, the parent of the offering. |
| Incident history fallback | When no offering is found, the workflow uses the offering most often seen on past incidents for the same host. |
| DRY_RUN | Setting in the workflow. When true, it builds everything but does not send. |
| correlation_id | Incident field holding the Dynatrace problem id. Used to avoid duplicates. |
| Non-Operational | Offering status meaning it is marked as not in active use. |
