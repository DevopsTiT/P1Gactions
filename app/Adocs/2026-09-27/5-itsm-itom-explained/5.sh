# ITSM vs ITOM tables - STG only - you run
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/incident?sysparm_query=active%3Dtrue&sysparm_limit=5&sysparm_fields=number,priority,cmdb_ci,assignment_group&sysparm_display_value=true"
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/problem?sysparm_limit=5&sysparm_fields=number,state,short_description"
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/change_request?sysparm_limit=5&sysparm_fields=number,type,state,start_date"
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/em_event?sysparm_limit=5&sysparm_fields=source,node,type,severity,message_key,state"
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/em_alert?sysparm_limit=5&sysparm_fields=number,source,node,severity,state,incident"
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/cmdb_ci_server?sysparm_query=name%3Dhost-app-01&sysparm_fields=name,install_status,operational_status,support_group&sysparm_display_value=true"
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/stats/em_event?sysparm_count=true&sysparm_group_by=source"
# git add/commit/push only if user asks
