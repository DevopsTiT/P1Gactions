# Environment Pairs Picture

## Decision tree

```
Need env → business service pairs
 ├─ Export service_offering + parent.* (31.sh line 2)
 ├─ Environment: offering Environment → service Used for → 3rd part of offering name
 ├─ Application: service name minus -dev / _PRD suffix
 └─ 31-env-service-pairs.py → long table + wide table
```

## Data flow

```
service_offering ──parent──► cmdb_ci_service
        │ environment             │ used_for
        └────────── export CSV ───┘
                     ▼
          pivot script (env + app stem)
                     ▼
     long CSV  /  wide CSV  ──► SYSTEM_MAP[system][env]
```
