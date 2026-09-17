# Result

Full architecture documented in `20-dynatrace-snow-pd-architecture.md`.

| Layer | Owner path |
| --- | --- |
| Detect | Dynatrace Davis Problem |
| Automate | OPEN + CLOSE Workflows |
| Ticket | ServiceNow via Connector (`snow-*`) |
| Page | PagerDuty Events API |
| Sync | `dt-problem-<problemId>` |
| Classic notification | Optional ITOM; ITSM OFF |

Upload workflows from seq 19 when ready to implement.
