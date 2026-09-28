# Read an INC like the example - STG only - you run
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/incident?sysparm_query=number%3DINC0098765&sysparm_display_value=true&sysparm_exclude_reference_link=true"
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/incident?sysparm_query=number%3DINC0098765&sysparm_fields=sys_id,state,impact,urgency,priority"
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/sys_journal_field?sysparm_query=element_id%3D__SYS_ID__%5EORDERBYsys_created_on&sysparm_fields=sys_created_on,sys_created_by,element,value"
curl -s -u "Tech_DynatraceJP_WS:__SNOW_PASSWORD__" -H "Accept: application/json" "https://silvastg.service-now.com/api/now/v2/table/task_sla?sysparm_query=task%3D__SYS_ID__&sysparm_fields=sla,stage,has_breached,business_percentage&sysparm_display_value=true"
# git add/commit/push only if user asks
