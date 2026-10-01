# Glossary

| Term | What it means |
|---|---|
| Table API | ServiceNow REST API `/api/now/v2/table/<table>` to read and write records. |
| sys_id | 32-character unique id of any ServiceNow record. |
| Reference field | Field that points to another record; must hold a sys_id. |
| sys_dictionary | Table describing every field: key, label, type. |
| sys_choice | Table of allowed values for dropdown fields. |
| cmdb_ci | Base table of all configuration items (servers, services...). |
| svc_ci_assoc | Link table: CI belongs to a service. |
| cmdb_rel_ci | Relationship table: parent, child, relationship type. |
| service_offering | Child of a business service, usually one per environment. |
| Events API v2 | PagerDuty API to trigger, acknowledge and resolve alerts. |
| Routing key | PagerDuty service integration key used by Events API v2. |
| DQL | Dynatrace Query Language used in Notebooks and Dashboards. |
| Allowlist | Dynatrace setting listing hosts that workflow JavaScript may call. |
