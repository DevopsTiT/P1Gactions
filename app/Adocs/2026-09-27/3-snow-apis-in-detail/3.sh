# SNOW API examples - STG only - you run
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" -H "Content-Type: application/json" -X POST "https://silvastg.service-now.com/api/now/v2/table/incident" -d '{"short_description":"[Dynatrace] test","correlation_id":"P-12345","impact":"3","urgency":"3"}'
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/incident?sysparm_query=correlation_id%3DP-12345%5Eactive%3Dtrue&sysparm_fields=sys_id,number,state&sysparm_limit=1"
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/incident/__SYS_ID__?sysparm_display_value=true&sysparm_exclude_reference_link=true"
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" -H "Content-Type: application/json" -X PATCH "https://silvastg.service-now.com/api/now/v2/table/incident/__SYS_ID__" -d '{"state":"6","close_code":"Solved (Permanently)","close_notes":"test resolve"}'
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/stats/incident?sysparm_query=active%3Dtrue&sysparm_count=true"
curl -s -o /dev/null -w "%{http_code}\n" "https://silvastg.service-now.com/api/now/v2/table/incident?sysparm_limit=1"
# git add/commit/push only if user asks
