# Pic

```
create  → POST  /api/now/v2/table/incident          → 201 sys_id, number
find    → GET   ...?sysparm_query=correlation_id=X  → 200 [] or [row]
resolve → PATCH .../incident/{sys_id} state=6       → 200
errors  → net=allowlist 401=login 403=role 404=path 400=body
```
