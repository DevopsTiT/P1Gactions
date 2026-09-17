# Glossary

| Term | What it means |
| --- | --- |
| Environment API | Dynatrace `/api/v2/...` for Problems, metrics, entities, etc. |
| Table API | ServiceNow CRUD on tables under `/api/now/v2/table/...` |
| Events API v2 | PagerDuty alert ingest at `events.pagerduty.com/v2/enqueue` |
| PD REST API | PagerDuty management API at `api.pagerduty.com` |
| Splunk REST | Management API under `/services/...` (often port 8089) |
| HEC | Splunk HTTP Event Collector for ingest |
| Connector | Dynatrace wrapper that calls SNOW Table API for you |
