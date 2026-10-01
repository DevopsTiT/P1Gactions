# Result

| Outcome | Detail |
|---|---|
| OPEN | 5 tasks in a line. Only tasks 4 and 5 send anything. |
| CLOSE | 1 prepare task, then SILVA and PagerDuty resolve in parallel |
| External APIs | Dynatrace Problems API, SILVA Table API (GET, POST, PATCH), PagerDuty Events API v2 |
| Link between OPEN and CLOSE | `correlation_id` and `dedup_key`, both built from `display_id` |

## What To Do Next

| Step | Why |
|---|---|
| Grant `environment-api:problems:read` | Task 1 of both workflows gets extra evidence |
| Allowlist `silvastg.service-now.com` and `events.pagerduty.com` | Otherwise every call fails |
| Run the INC30340215 GET in `13.sh` | Confirms real choice values for state, close code, impact, urgency |
| Test OPEN with `DRY_RUN` true on a real event | See the bodies without creating tickets |
| Test the PagerDuty trigger and resolve curls | Confirms the routing key works |
| Deactivate old OPEN and CLOSE workflows | Avoid double tickets |
