# SILVA Payload Mapping Pic

```
Dynatrace event
  affected = SERVICE (no host.name)
        │
        ▼ today
  cmdb_ci = service name ──► SILVA: no CI match ──► no business service ──► default offering

        ▼ proposed
  tags: silva_business_service / silva_group_l1 / silva_group_l2
  service → host (relationships) → system name
        │
        ▼
  SILVA lookup ── match ──► business service + group
               └─ no match ► default SILVA business service + default group
```
