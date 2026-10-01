# Workflow Flow Result

| Task | Calls | Main output |
|---|---|---|
| 1 extract-event-tags | Problems API v2 (GET) | dynatrace_alert, snow_inputs |
| 2 resolve-snow-values | SILVA GET | snow_required, steps |
| 3 build-payload | None | snow_incident_payload, pagerduty_payload, decision |
| 4a SILVA | PREVIEW: GET duplicate. OPEN: GET duplicate and POST incident. | ready or incident number |
| 4b PagerDuty | PREVIEW: none. OPEN: POST enqueue. | checks or PagerDuty response |

To debug a run, read task 2 `steps` first. It lists every SILVA call with its query, HTTP status and match count.
