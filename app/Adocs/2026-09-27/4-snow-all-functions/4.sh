# Explore SNOW tables per module - STG only - you run
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/incident?sysparm_limit=1&sysparm_fields=number,state,priority"
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/problem?sysparm_limit=1&sysparm_fields=number,state"
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/change_request?sysparm_limit=1&sysparm_fields=number,state,type"
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/kb_knowledge?sysparm_limit=1&sysparm_fields=number,short_description"
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/cmdb_ci_server?sysparm_limit=1&sysparm_fields=name,install_status,operational_status"
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/em_event?sysparm_limit=1&sysparm_fields=source,node,severity"
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/task_sla?sysparm_limit=1&sysparm_fields=task,sla,has_breached"
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/stats/incident?sysparm_query=active%3Dtrue&sysparm_count=true&sysparm_group_by=priority"
# git add/commit/push only if user asks
