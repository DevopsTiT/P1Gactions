# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Davis problem | A Dynatrace-detected issue with a status (ACTIVE, CLOSED) | It is the trigger for both workflows |
| `display_id` | The human problem ID, for example P-2609123 | Used to build both sync keys |
| Task | One box in the workflow that runs a JavaScript script | Each has one job |
| `ex.result("<id>")` | Reads what an earlier task returned | The only way tasks share data |
| SILVA | The AXA ServiceNow instance | Where incidents live |
| Table API | ServiceNow REST API at `/api/now/v2/table/<table>` | Every SILVA read and write goes through it |
| `sysparm_query` | The filter in a Table API call, for example `name=X^active=true` | Decides which rows come back |
| `^` and `^OR` | AND and OR inside `sysparm_query` | Combine conditions |
| `LIKE`, `STARTSWITH` | Contains and starts-with filters | Loose name matching |
| Dot-walk | `assignment_group.name` reads a field of a linked record | Search services by group name |
| sys_id | 32-character internal ID of a SILVA record | Reference fields store this |
| CI | Configuration item: a server, DB or service record in the CMDB | Used to find the owning service |
| Business service | `cmdb_ci_service` record the incident is about | Required form field |
| Service offering | Child of a business service, often per environment | Required form field |
| `correlation_id` | Incident field we fill with `display_id` | CLOSE finds the ticket with it |
| PagerDuty Events API v2 | `POST /v2/enqueue` with trigger or resolve | Pages and un-pages on-call |
| Routing key | Integration key of a PagerDuty service | Decides who gets paged |
| `dedup_key` | PagerDuty grouping key | Trigger and resolve must match |
| `DRY_RUN` | Log only, send nothing | Safe testing |
