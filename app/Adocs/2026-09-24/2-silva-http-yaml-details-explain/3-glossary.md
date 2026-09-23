# Glossary

| Term | What it means |
| --- | --- |
| Workflow YAML | Dynatrace automation definition you import |
| schemaVersion 3 | Current workflow format in these files |
| eventTrigger | Starts on a Davis Problem event |
| filterQuery | DQL-like condition on the event |
| predecessors | Tasks that must finish first |
| run-javascript | JS task that can call fetch |
| correlation_id | SNOW field linking to Dynatrace problem |
| dedup_key | PD field linking trigger and resolve |
| PATCH state 6 | Common SNOW Resolved state value |
| parallel tasks | Same predecessor, different x position |
| External requests | Outbound allowlist in Dynatrace |
| Placeholder | `__SNOW_PASSWORD__` / `__PD_ROUTING_KEY__` to replace |
