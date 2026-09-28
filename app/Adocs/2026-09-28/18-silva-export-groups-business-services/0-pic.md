# SILVA Export Pic

```
Need lists?
 ├─ by hand → SILVA UI <table>.list → Export CSV  (or <table>_list.do?CSV in browser)
 └─ script  → Table API GET → jq → CSV
       sys_user_group   → assignment groups
       cmdb_ci_service  → business services
       service_offering → offerings (parent = service)
       svc_ci_assoc / cmdb_rel_ci → host → service
       cmdb_ci_server   → host's group
 empty / 403 → API user lacks read → use your UI login or ask admin
```
