# Glossary

| Term | What it means | Why you care |
|---|---|---|
| Resolved (state 6) | ServiceNow state meaning the work is done. | This is the state you set to "close" a ticket. |
| Closed (state 7) | Final state, normally set by the system. | You usually cannot pick it by hand. |
| Auto-close timer | System job that moves Resolved to Closed after some days. | Explains why the ticket stays Resolved for a while. |
| Resolution code (close_code) | Required reason for resolving, like "Solved (Permanently)". | The form will not resolve without it. |
| Resolution notes (close_notes) | Free text explaining the fix. | Usually mandatory on resolve. |
| sys_id | Unique internal ID of a ServiceNow record. | The API needs it to update one ticket. |
| correlation_id | Field the workflow uses to link an incident to a Dynatrace problem. | Without it, the CLOSE workflow cannot find the ticket. |
| PATCH | HTTP method that changes some fields of a record. | Used to set the ticket to Resolved by API. |
