# Investigation

| What was considered | Finding |
|---|---|
| Where SNOW stores assignment groups | `sys_user_group` table. We already queried it for testing 3122 and Ops_Middleware_Monitoring_AXAJP. |
| Where business services live | `cmdb_ci_service`. Seq 16 already looks up uk-sap-fscd-dev there. |
| Where offerings live | `service_offering`, with `parent` pointing to the business service. |
| How SILVA maps a host to a service | Service mapping (`svc_ci_assoc`) or CI relationships (`cmdb_rel_ci`), per Davesh's comment that SILVA picks the service from the host. |
| API user access | Not confirmed. Earlier lookups were written but not run, so read access on these tables is unknown. |
| Export limits | UI and URL CSV exports are usually capped around 10,000 rows. |
