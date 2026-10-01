# SILVA Objects Pic

```
core_company (AXA XL)
  └─ cmdb_ci_service  Business service   → incident.u_business_service
       └─ service_offering  Service Offering → incident.cmdb_ci
            └─ cmdb_ci  server ts12        → incident.u_configuration_item
sys_user_group  team                       → incident.assignment_group
sys_user  Dynatrace JP                     → incident.caller_id, u_on_behalf_of
display_id P-261090                        → incident.correlation_id

Every arrow stores a sys_id (32 hex chars), not a name.
```
