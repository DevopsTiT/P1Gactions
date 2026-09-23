# Glossary

| Term | What it means |
| --- | --- |
| SILVA | ServiceNow-side integration / instance used as ticket gate |
| snow connector | Dynatrace `dynatrace.servicenow:snow-*` workflow actions |
| run-javascript | Workflow task that runs JS and can `fetch` HTTP |
| External requests | Dynatrace outbound host allowlist |
| correlation_id | SNOW field used to find the INC later |
| dedup_key | PagerDuty key that ties trigger and resolve |
| CMDB | Config DB; SILVA may skip retired hosts |
| Events API | `POST /v2/enqueue` for PD trigger/resolve |
| Table API | SNOW REST `/api/now/v2/table/incident` |
