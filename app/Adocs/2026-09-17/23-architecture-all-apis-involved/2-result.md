# Result

API inventory complete.

| Family | Endpoints used in this design |
| --- | --- |
| ServiceNow | `POST/GET/PUT /api/now/v2/table/incident` |
| PagerDuty | `POST /v2/enqueue` (trigger + resolve) |
| Dynatrace | Internal Problem event + Workflow JS (no outbound REST you author) |

Also mirrored into `20-dynatrace-snow-pd-architecture.md` §13.
