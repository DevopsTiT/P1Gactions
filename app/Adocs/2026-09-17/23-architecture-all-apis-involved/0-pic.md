# Pic — All APIs Involved

```
Problem event (internal)
  → JS prepare (internal)
  → POST /api/now/v2/table/incident
  → POST /v2/enqueue (PD trigger)
  → PUT  /api/now/v2/table/incident/{sys_id}

Problem close (internal)
  → GET  /api/now/v2/table/incident
  → PUT  /api/now/v2/table/incident/{sys_id}
  → POST /v2/enqueue (PD resolve)
```
