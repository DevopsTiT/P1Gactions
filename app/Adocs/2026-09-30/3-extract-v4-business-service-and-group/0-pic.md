# Business Service And Group Pic

## Decision tree

```
Need SNOW values
 │
 ├─ ASSIGNMENT GROUP
 │    ├─ GROUP_MAP set? → check active in SILVA → use
 │    ├─ tag AGO_AXA_SUPPORTGROUP? → check → use
 │    ├─ specific tag (AGO_ORACLE_ASSIGNMENT_GROUP)? → check → use
 │    ├─ AGO_DEFAULT_ASSIGNMENT_GROUP? → check → use
 │    ├─ business service has a group? → use
 │    ├─ CI has a support group? → use
 │    └─ default Ops_Middleware_Monitoring_AXAJP
 │
 └─ BUSINESS SERVICE
      ├─ SERVICE_MAP or service tag → exact name
      ├─ host or DB CI
      │    ├─ CI business_service field
      │    ├─ svc_ci_assoc
      │    └─ cmdb_rel_ci parent service
      ├─ scored search
      │    ├─ group sys_id
      │    ├─ DB type + environment
      │    ├─ DB type + region
      │    └─ trigram
      └─ not found → read candidates → fill SERVICE_MAP
```

## Data flow

```
event tags ──► extract-event-tags ──► snow_inputs
                                         │
                                         ▼
                              resolve-snow-values ── GET ──► SILVA
                                         │
                                         ▼
                              display-result ──► snow_required + previews
```
