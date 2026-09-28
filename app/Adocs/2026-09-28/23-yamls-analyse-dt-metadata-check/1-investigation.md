# Investigation

| What was checked | Finding |
|---|---|
| OPEN prepare-payload | Reads event.name, display_id, event.id, event.severity, event.category, host.name, entity_tags, dt.security.context, entity names. |
| OPEN Problems API call | getProblem(event.id) gives entityTags, rootCauseEntity, evidenceDetails, managementZones, impactLevel. |
| Severity order | event.severity is read before event.category, so the sample gives "3". |
| Host | Sample event has no host.name; ciName falls back to the root cause service name. |
| SYSTEM_MAP | Only EIP is active; COMPASSPROXY is commented out. |
| Fixed values | FIXED_ENVIRONMENT, FIXED_IMPACT, FIXED_URGENCY override the event. |
| CLOSE | Uses display_id and getProblem for notes; searches INC by correlation_id and PATCHes Resolved. |
