# Investigation

| What was checked | Finding |
|---|---|
| OPEN trigger (lines 48–63) | ACTIVE with CREATED, UPDATED or REOPENED. All categories, no tag filter. |
| OPEN `readEventMeta` (lines 163–203) | Parses `entity_tags`, META_FIELDS, affected entities, host fields and security context |
| OPEN Problems API (lines 253–285) | Title, ids, impact, severity, root cause, evidence event properties |
| OPEN Entities API (lines 287–320) | Root entity, then host through `fromRelationships`. Host name, IPs, tags, zones. |
| OPEN decisions (lines 322–377) | Severity table, fixed 4/4, system map, environment, service, offering, group order |
| OPEN text (lines 379–436) | Short description, Additional Information JSON, notes, metadata block |
| OPEN POST task (lines 499–727) | cmdb_ci lookup, deriveFromCi, POST, svc_ci_assoc fallback, PATCH, stored and notFilled |
| OPEN PagerDuty (lines 729–806) | trigger with dedup_key and custom_details |
| CLOSE (whole file) | Same display id, GET limit 1, PATCH state 6, PagerDuty resolve |
| Risks | UPDATED duplicates, limit=1 close, EIP forces Production, placeholders in CLOSE notes, secrets in the file |
| Commands run | None |
