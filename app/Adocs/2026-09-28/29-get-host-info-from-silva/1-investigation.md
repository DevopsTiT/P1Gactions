# Investigation

| What was checked | Finding |
|---|---|
| Example tickets | Business service filled from the CI (host), group and env from AGO tags. |
| Tables involved | cmdb_ci / cmdb_ci_server, svc_ci_assoc, cmdb_ci_service, service_offering, sys_user_group, sys_choice, incident. |
| Access | API user Tech_DynatraceJP_WS may lack read access on CMDB tables; the UI with a personal login is the fallback. |
