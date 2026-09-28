# Service Sys ID Pic

```
names in settings
   │
   ├─ GET cmdb_ci_service  → bs sys_id  ─┐
   ├─ GET service_offering → so sys_id  ─┤
   ▼                                     ▼
POST incident (sys_ids, impact 4, urgency 4) → PATCH service fields by sys_id
   │
   ▼
result: serviceLookup (matches, status) + serviceFix (what SNOW kept)
   matches 0 → wrong name / no read access
   matches 2 → not unique → use sys_id in settings
   kept blank → SEND_CONFIGURATION_ITEM = false
```
