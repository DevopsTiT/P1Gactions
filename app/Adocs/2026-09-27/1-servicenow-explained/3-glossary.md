# Glossary

| Term | What it means |
| --- | --- |
| ServiceNow (SNOW) | SaaS platform for IT tickets and processes |
| ITSM | IT Service Management (incidents, changes, requests) |
| ITOM | IT Operations Management (events, discovery) |
| Incident | Something broken now; `INC` number |
| Problem (SNOW) | Root cause record behind repeated incidents |
| Change | Planned production change; `CHG` number |
| CMDB | Inventory of servers, apps, and their links |
| CI | Configuration item: one entry in the CMDB |
| sys_id | Internal unique id of any SNOW record |
| correlation_id | External reference; we store the Dynatrace problem id |
| SILVA | Gatekeeper that receives alerts and creates SNOW incidents |
| Table API | REST API `/api/now/v2/table/<table>` |
| em_event | ITOM event table |
