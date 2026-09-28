# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Davis problem | A problem Dynatrace AI opens after grouping related events | This is what triggers both workflows |
| display_id | The readable problem number, such as P-2609123 | The sync key between OPEN and CLOSE |
| event.id | The internal problem id | Used to call the Problems API |
| Evidence event | An event attached to the problem as proof of the cause | Holds the description and properties |
| rootCauseEntity | The entity Davis blames for the problem | Sets isRootCause and the root name |
| fromRelationships | The links from an entity to others, such as "runs on host" | How a process leads to its host |
| entity_tags | The tags on affected entities, sent in the trigger event | Source of group and environment |
| Security context | `dt.security.context`, the permission scope string | Backup source for the environment |
| run-javascript | A workflow task that runs your JavaScript | All three tasks use it |
| predecessors / conditions | Which task must finish first, and in which state | SILVA and PagerDuty only run if prepare is OK |
| correlation_id | A SILVA incident field for an external id | CLOSE searches on it |
| dedup_key | The PagerDuty incident key | Trigger and resolve must use the same one |
| sys_id | The unique id of a SILVA record | Reference fields are reliable only with sys_ids |
| Insert rules | SILVA business rules that run when a record is created | They can change fields, hence the PATCH afterwards |
