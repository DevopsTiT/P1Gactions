# Result

| Step | System | Call | Link key |
|---|---|---|---|
| OPEN 1 | Dynatrace | GET problem | display_id |
| OPEN 2 | SILVA | Many GETs | host, tags |
| OPEN 4a | SILVA | GET incident | correlation_id |
| OPEN 5a | SILVA | GET then POST incident | correlation_id |
| OPEN 5b | PagerDuty | POST enqueue trigger | dedup_key |
| CLOSE 1 | Dynatrace | GET problem | display_id |
| CLOSE 2a | SILVA | GET sys_choice, GET incident, PATCH | correlation_id |
| CLOSE 2b | PagerDuty | POST enqueue resolve | dedup_key |

Replay any step by hand with the curl lines in `47.sh`.
