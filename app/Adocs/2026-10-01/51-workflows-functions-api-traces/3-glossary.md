# Glossary

| Term | What it means | Why you care |
|---|---|---|
| main (default function) | The function Dynatrace runs for a task. | Entry point of every task. |
| Helper function | A small function main calls. | Most logic lives here. |
| Call graph | Picture of which function calls which. | Find where an API call comes from. |
| Trace | Ordered list of calls made in one run. | Debug what really happened. |
| SDK | Dynatrace JavaScript libraries. | `execution`, `problemsClient`, `getEnvironmentUrl`. |
| `fetch` | JavaScript HTTP call. | All SILVA and PagerDuty calls. |
| `steps` | Task 2 list of every SILVA GET. | Built-in trace for lookups. |
| `attempts` | CLOSE 2a list of every PATCH. | Built-in trace for resolving. |
| Automation API | Dynatrace REST API for workflows and executions. | Pull results and logs by script. |
| Platform token | Token for `apps.dynatrace.com` platform APIs. | Needed for the Automation API. |
| sys_audit | SILVA table of field changes. | Proves what the workflow changed. |
| sys_journal_field | SILVA table of work notes and comments. | Shows the notes text. |
| log_entries | PagerDuty incident history API. | Shows trigger and resolve. |
