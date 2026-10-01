# Result

| Workflow | Calls in this example | End state |
|---|---|---|
| OPEN | 1 Dynatrace, 11 SILVA GET, 1 SILVA POST, 1 PagerDuty | INC30341416 New, PD triggered |
| CLOSE | 1 Dynatrace, 6 SILVA GET, 1 SILVA PATCH, 1 PagerDuty | INC30341416 Resolved, PD resolved |

Compare with your run: OPEN task 2 `steps` and CLOSE 2a `attempts`.
