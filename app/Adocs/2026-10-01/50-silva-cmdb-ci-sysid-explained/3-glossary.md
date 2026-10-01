# Glossary

| Term | What it means | Why you care |
|---|---|---|
| SILVA | AXA's ServiceNow instance. | Where incidents live. |
| sys_id | 32-character unique record id. | Reference fields store it. |
| CMDB | Configuration Management Database. | Inventory of servers, apps, services. |
| CI | Configuration Item, one thing in the CMDB. | The server the problem is on. |
| cmdb_ci (table) | Base table of every CI. | Where the server is found. |
| cmdb_ci (incident field) | In SILVA, the Service Offering field. | Holds the offering sys_id. |
| u_configuration_item | AXA custom incident field for the server CI. | Holds the host CI sys_id. |
| Business service | `cmdb_ci_service` record, what the business uses. | Goes into u_business_service. |
| Service offering | `service_offering` record, the service in one environment. | Goes into cmdb_ci. |
| Assignment group | `sys_user_group` record, a team. | Owns the ticket. |
| core_company | Company table. | Mandatory company field. |
| sys_user | User table. | Caller and On Behalf Of. |
| Reference field | Field pointing to another record by sys_id. | Send sys_ids, not names. |
| Display value | Readable name of a reference. | What the form shows. |
| Choice field | Dropdown with fixed values. | Environment, state, close code. |
| sys_choice | Table of choice values. | Check allowed values. |
| sys_class_name | The exact class of a CI. | Tells server from offering. |
| Table inheritance | One table extending another. | Why offerings appear in service searches. |
| svc_ci_assoc | CI to service link table. | Finds the service of a server. |
| cmdb_rel_ci | CI relationship table. | Another way to find parent services. |
| correlation_id | Outside system id on the incident. | Links Dynatrace to SILVA. |
| incident_state | SILVA's real state field. | Must be Resolved on close. |
| u_ prefix | Custom field added by AXA. | Not in standard ServiceNow docs. |
