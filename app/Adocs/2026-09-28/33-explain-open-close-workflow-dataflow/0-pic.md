# OPEN And CLOSE Picture

## Decision tree

```
Problem event
 ├─ ACTIVE → OPEN
 │    prepare-payload: event → getProblem → evidence event → getEntity(host)
 │       host:    entity displayName → event host → host+domain tag → "on host X"
 │       env:     SYSTEM_MAP → AGO_AXAENVIRONMENTNAME tag → security context → Development
 │       service: SYSTEM_MAP → service tag → (default = let SILVA derive from CI)
 │       group:   AGO_AXA_SUPPORTGROUP tag → map L2 → Ops_Middleware_Monitoring_AXAJP
 │    post-silva: cmdb_ci lookup → POST incident → svc_ci_assoc if blank → PATCH
 │    trigger-pagerduty: dedup_key dt-problem-<display_id>
 └─ CLOSED → CLOSE
      prepare-close-ids: display_id → correlationId, dedupKey, notes
      resolve-silva: GET by correlation_id → PATCH state 6
      resolve-pagerduty: resolve dedup_key
```

## Data flow

```
event ─► prepare ─┬─► SILVA  (correlation_id = display_id)
                  └─► PagerDuty (dedup_key = dt-problem-display_id)
close event ─► prepare ─┬─► SILVA GET by correlation_id ─► PATCH Resolved
                        └─► PagerDuty resolve same dedup_key
```
