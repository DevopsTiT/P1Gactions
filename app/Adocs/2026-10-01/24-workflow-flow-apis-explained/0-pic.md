# Workflow Flow Picture

```
trigger (DAVIS_PROBLEM CREATED)
  → 1 extract-event-tags   [Problems API v2 GET]
  → 2 resolve-snow-values  [SILVA GET: sys_user_group, cmdb_ci, svc_ci_assoc, cmdb_rel_ci, cmdb_ci_service, service_offering]
  → 3 build-payload        [no network]
  ├→ 4a SILVA      PREVIEW: GET incident (dup)   | OPEN: GET dup + POST incident
  └→ 4b PagerDuty  PREVIEW: checks only          | OPEN: POST events.pagerduty.com/v2/enqueue
```
