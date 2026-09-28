# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Trigger event | JSON Dynatrace passes to the workflow | First source of metadata. |
| Problems API | Dynatrace API returning full problem details | Adds tags, root cause and evidence. |
| prepare-payload | First OPEN task that builds all SNOW fields | This is where analysis happens. |
| event.severity | Numeric severity level in the event | Not a word like SLOWDOWN, so keyword rules miss it. |
| event.category | Problem type such as SLOWDOWN or ERROR | Better input for severity rules. |
| cmdb_ci | SNOW configuration item field | Sending an unknown name makes SILVA guess. |
| correlation_id | Problem id stored on the INC | Lets CLOSE find the same ticket. |
