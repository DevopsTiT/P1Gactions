# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Task | One box on the workflow canvas. | Each task runs one action, here JavaScript. |
| `predecessors` | The tasks that must finish before this one starts. | Two tasks with the same single predecessor run in parallel. |
| `conditions.states` | The result the predecessor must have: OK, ERROR or ANY. | ANY means "run no matter what happened". |
| `custom` condition | An expression that must be true for the task to run. | Used for the retired-CI skip. |
| `else: SKIP` | Mark the task as skipped when the condition is false. | Without it, the task shows as failed. |
| `position x/y` | Where the box is drawn on the canvas. | Visual only; it doesn't change the order. |
| `>-` | YAML folded text: joins the lines into one paragraph. | Used for descriptions. |
| `\|` | YAML literal text: keeps the lines as written. | Used for scripts. |
| `ex.result("name")` | Reads another task's return value. | How the tasks share data. |
| `correlation_id` | A SNOW field holding an outside system's ID. | The CLOSE search key. |
| `dedup_key` | The PagerDuty key that groups trigger and resolve events. | The same key resolves the same incident. |
| sys_id | SNOW's unique 32-character record ID. | Reference fields, such as the group, want this. |
| `display_value=all` | A SNOW option that returns both the code and the label. | For example `6` and `Resolved`. |
| `input_display_value=true` | A SNOW option that lets you send labels instead of codes. | A label that doesn't match is silently dropped. |
| Events API v2 | PagerDuty endpoint for trigger and resolve (routing key only). | No incident URL comes back. |
| REST API | PagerDuty endpoint for reading incidents and adding notes (API key). | Used to get `html_url`. |
| DQL | Dynatrace Query Language. | Used to fetch the top error log. |
| CMDB CI | A configuration item record, such as a server, in ServiceNow. | Gives the owner group and the retired status. |
