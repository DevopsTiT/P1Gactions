# Glossary

| Term | What it means |
| --- | --- |
| ServiceNow Connector | Dynatrace app `dynatrace.servicenow` with Connection + `snow-*` workflow actions |
| Connection | Stored SNOW URL + credentials used by snow tasks (no password in script) |
| snow-create-incident | Creates a ServiceNow INC via Connection |
| snow-comment-on-incident | Adds a work note / comment on an INC |
| snow-search-incidents | Finds INC rows (here by correlation_id) |
| snow-resolve-incident | Resolves an INC via Connection |
| correlation_id | SNOW field set to `dt-problem-<id>` so close can find the INC |
| dedup_key | PagerDuty key; same string as correlation_id for sync |
| Classic Problem notification | Settings integration (`servicenowstg`); not a workflow snow task |
| ITSM OFF | Turns off classic INC create so the Connector workflow does not double-create |
