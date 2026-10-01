# Investigation

| What was checked | Finding |
|---|---|
| seq 32 query set | Reused and extended into 11 read-only checks. |
| seq 30 workflow correlation_id | `correlation_id` is the Dynatrace problem id, so query 10 filters on it. |
| seq 30 duplicate check | Uses `correlation_id=<id>^active=true`, same filter as query 10. |
| Known IDs | Host CI `1dfdcf8a…`, expected offering `cfbf255f…` from INC30340215. |

No queries were run by the agent. The user runs `33.sh`.
