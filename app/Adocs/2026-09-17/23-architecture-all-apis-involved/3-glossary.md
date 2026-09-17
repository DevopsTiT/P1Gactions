# Glossary

| Term | What it means |
| --- | --- |
| Table API | ServiceNow REST API under `/api/now/v2/table/...` for CRUD on tables |
| Connector action | Dynatrace `snow-*` task that wraps a Table API call using a Connection |
| Events API v2 | PagerDuty endpoint `POST /v2/enqueue` for trigger/acknowledge/resolve |
| routing_key | PD integration key sent in the Events API JSON body |
| sys_id | ServiceNow record id used in PUT paths |
| Classic notification API | Separate Dynatrace→SNOW push for ITSM/ITOM; not Connector Table API |
