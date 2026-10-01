# Investigation

| What I checked | What I found |
|---|---|
| OPEN task 1 | `ex.event()` plus `problemsClient.getProblem`. |
| OPEN task 2 | Up to 18 kinds of SILVA GET across sys_user_group, cmdb_ci, svc_ci_assoc, cmdb_rel_ci, cmdb_ci_service, service_offering, incident. |
| OPEN task 3 and 4b | No network. |
| OPEN 4a | One GET on incident by correlation_id. |
| OPEN 5a | GET duplicate check, then POST incident. |
| OPEN 5b | POST PagerDuty enqueue, action trigger. |
| CLOSE task 1 | `ex.event()` plus `getProblem`. |
| CLOSE 2a | Five sys_choice GETs, one incident GET, one to three PATCHes per incident. |
| CLOSE 2b | POST PagerDuty enqueue, action resolve. |
| Real run | P-261090 created INC30341416; CLOSE resolved it through incident_state. |
