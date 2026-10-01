# Table Versus Field Pic

```
SILVA lists (tables)              Ticket boxes (incident fields)
sys_user_group   (teams)     ◄──  assignment_group
cmdb_ci_service  (services)  ◄──  u_business_service
service_offering (offerings) ◄──  cmdb_ci
cmdb_ci          (servers)   ◄──  u_configuration_item
core_company     (companies) ◄──  company
choice list      (words)     ◄──  u_environment
Each box stores the id of one row in its list.
```
