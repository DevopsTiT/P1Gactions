# Query Picture

```
payload key?
 ├─ all at once        → incident number=INC30340215 (display_value=all)
 ├─ reference field    → sys_user / sys_user_group / core_company / cmdb_ci_service / service_offering → sys_id
 ├─ choice field       → sys_choice name=incident^element=<field> → value
 └─ PagerDuty          → test trigger → test resolve (same dedup_key)
```
