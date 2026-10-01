# Glossary

| Term | What it means | Why you care |
|---|---|---|
| E2E | End to end: from the Dynatrace event to SILVA and PagerDuty and back. | Shows where a failure sits. |
| Problems API v2 | Dynatrace REST API `/api/v2/problems/{id}`. | Gives tags, times and evidence. |
| Table API | ServiceNow REST API `/api/now/v2/table/{table}`. | Every SILVA call uses it. |
| Encoded query | ServiceNow filter text, `^` for AND, `^OR` for OR. | Used in `sysparm_query`. |
| sys_id | 32-character record id in ServiceNow. | Reference fields need it. |
| Basic auth | User and password sent base64 encoded in a header. | How the workflow logs in to SILVA. |
| Events API v2 | PagerDuty `/v2/enqueue` endpoint. | Trigger and resolve alerts. |
| routing_key | PagerDuty integration key in the request body. | Picks the PD service. |
| dedup_key | PagerDuty id linking trigger and resolve. | Same value in OPEN and CLOSE. |
| correlation_id | SILVA incident field for an outside id. | CLOSE finds the ticket by it. |
| `ex.result()` | Reads an earlier task's return value. | How data moves between tasks. |
| HTTP 201 | Created. | SILVA POST success. |
| HTTP 202 | Accepted. | PagerDuty success. |
| External requests allowlist | Dynatrace list of hosts a workflow may call. | Without it, every outside call fails. |
