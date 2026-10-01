# Glossary

| Term | What it means |
|---|---|
| PATCH | HTTP method that changes only the fields you send on an existing record. |
| sys_choice | SILVA table holding the allowed values for dropdown fields like state and close_code. |
| close_code | The resolution code dropdown on the incident. |
| close_notes | The resolution notes text. |
| work_notes | Internal note on the incident, not sent to the caller. |
| comments | Additional comments, visible to the caller. |
| active | true while the incident is open; false once resolved or closed. |
| event_action resolve | PagerDuty Events v2 action that closes the alert with that dedup_key. |
| onProblemClose | Dynatrace trigger option to start the workflow when a problem closes. |
