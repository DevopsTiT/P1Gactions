SNOW_USER='Tech_DynatraceJP_WS'
SNOW_PASS='<password>'
SNOW='https://silvastg.service-now.com'
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/cmdb_ci_service" --data-urlencode 'sysparm_query=name=QA Platforms' --data-urlencode 'sysparm_fields=sys_id,name,number,company,assignment_group' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/service_offering" --data-urlencode 'sysparm_query=parent.name=QA Platforms^nameSTARTSWITHQA Platforms - AXA GROUP OPERATIONS' --data-urlencode 'sysparm_fields=sys_id,name,u_environment' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/sys_user_group" --data-urlencode 'sysparm_query=name=Ops_Middleware_Monitoring_AXAJP^active=true' --data-urlencode 'sysparm_fields=sys_id,name,company' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/sys_choice" --data-urlencode 'sysparm_query=name=incident^element=u_environment^inactive=false' --data-urlencode 'sysparm_fields=label,value' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/sys_user" --data-urlencode 'sysparm_query=name=Shuge KUI' --data-urlencode 'sysparm_fields=sys_id,name,user_name' | jq
mkdir -p "/Users/k/Work/AIProjects/Files/2026-09-30" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-09-30"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-30/8-v5-default-qa-platforms-fallback" "/Users/k/Work/AIProjects/Files/2026-09-30/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-30/8-v5-default-qa-platforms-fallback" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-09-30/"
# Do NOT push app/Adocs: the workflow YAML contains the SNOW password
