# E2E Pic

```
OPEN (problem CREATED)
event ─► [1] Problems API GET /api/v2/problems/{id}
      ─► [2] SILVA GET sys_user_group, cmdb_ci, svc_ci_assoc, cmdb_rel_ci,
             cmdb_ci_service, service_offering, incident (history)
      ─► [3] build bodies (no network)
      ├─► [4a] SILVA GET incident (duplicate) ─► [5a] SILVA GET + POST /incident
      └─► [4b] checks (no network)            ─► [5b] PD POST /v2/enqueue trigger

CLOSE (problem CLOSED)
event ─► [1] Problems API GET /api/v2/problems/{id}
      ├─► [2a] SILVA GET sys_choice x5 ─► GET incident ─► PATCH x1..3
      └─► [2b] PD POST /v2/enqueue resolve

Link: correlation_id = P-261090    dedup_key = dt-problem-P-261090
```
