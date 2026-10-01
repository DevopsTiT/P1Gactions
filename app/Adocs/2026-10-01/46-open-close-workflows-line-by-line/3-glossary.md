# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Davis problem | A Dynatrace problem found by its AI engine (Davis). | It is the event that starts both workflows. |
| display_id | Human problem id such as P-261090. | The sync key for both SILVA and PagerDuty. |
| run-javascript task | A workflow step that runs your JavaScript in Dynatrace. | Every task in both workflows is one. |
| predecessors | The tasks that must finish before this one. | Defines the chain and the parallel branches. |
| conditions.states OK | Run only if the predecessor succeeded. | A red task stops everything under it. |
| `ex.event()` | Reads the trigger event. | Empty on manual Run, so the sample is used. |
| `ex.result("task")` | Reads another task's return value. | How tasks pass data. |
| Table API | ServiceNow REST API at `/api/now/v2/table/<table>`. | All SILVA GET, POST and PATCH calls use it. |
| sys_id | 32-character ServiceNow record id. | Reference fields need this, not a name. |
| `sysparm_display_value=all` | Return both the stored value and the display name. | Used by the `val` and `dv` helpers. |
| sys_choice | Table of allowed dropdown values. | CLOSE checks state and close code against it. |
| correlation_id | Incident field for an outside system id. | OPEN writes it; CLOSE searches by it. |
| incident_state | SILVA's real "Incident State" field. | Must be set, or the state does not change. |
| dedup_key | PagerDuty id tying trigger and resolve together. | Same value in OPEN and CLOSE. |
| Events API v2 | PagerDuty endpoint `/v2/enqueue`. | Used for trigger and resolve. |
| DRY_RUN | Build and log only, send nothing. | Safe testing. |
| ALLOW_SAMPLE_POST | Let the manual Run sample really send. | Off by default to avoid fake tickets. |
