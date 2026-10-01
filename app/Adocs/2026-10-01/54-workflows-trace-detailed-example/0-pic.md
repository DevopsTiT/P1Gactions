# Detailed Example Pic

```
OPEN P-261090
 T1  ex.event → getProblem → parseTag/allByKey/envLabel → host ts12, env Pre-Production
 T2  cmdb_ci ts12 → svc_ci_assoc → tech service → offerings 0
     → incident history 20/20 cfbf255f → offering parent 37273dbc → AXA XL
 T3  body (correlation_id P-261090), PD body (dt-problem-P-261090), decision create
 T4a GET dup none → ready      T4b checks OK → ready
 T5a GET dup none → POST 201 INC30341416
 T5b POST enqueue 202

CLOSE P-261090
 T1  is_closed true, duration 1 h 12 min (example)
 T2a sys_choice x5 → GET incident → PATCH state+incident_state=Resolved → 200 Resolved
 T2b POST enqueue resolve 202
```
