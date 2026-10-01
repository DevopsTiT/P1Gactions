# Investigation

| Source | Finding |
|---|---|
| OPEN task 2 (lines 312 to 763) | Tables: sys_user_group, cmdb_ci, svc_ci_assoc, cmdb_rel_ci, cmdb_ci_service, service_offering, incident. |
| OPEN task 3 (lines 828 to 849) | Field mapping into the incident body. |
| Earlier SILVA checks | `business_service` field is ZZZ-Do-not-use; `cmdb_ci` is labelled Service Offering; host goes to `u_configuration_item`. |
| P-261090 | Offering cfbf255f, business service 37273dbc, company AXA XL. |
