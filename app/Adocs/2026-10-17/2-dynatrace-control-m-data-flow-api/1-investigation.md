# Control-M Data Flow Investigation

| Source | Finding |
|---|---|
| Your seq 39 / 40 | Abend and overrun are log detectors only |
| Dynatrace Jobs v2 docs | ActiveGate polls Automation API; metrics controlm.* |
| BMC Run service | GET /run/jobs/status and GET /run/job/{id}/status |
| BMC CTM-13123 | OneAgent 1.327 unsafe on EM Linux |

Auth header name depends on Control-M version (`x-api-key` or `Authorization: Bearer`). Confirm against your EM API docs before scripting.
