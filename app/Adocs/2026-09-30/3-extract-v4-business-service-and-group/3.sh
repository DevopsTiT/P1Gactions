SNOW_USER='Tech_DynatraceJP_WS'
SNOW_PASS='<password>'
SNOW='https://silvastg.service-now.com'
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/sys_user_group" --data-urlencode 'sysparm_query=name=Database_AXAJP^active=true' --data-urlencode 'sysparm_fields=sys_id,name,active' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/cmdb_ci" --data-urlencode 'sysparm_query=name=deaa310b^ORnameSTARTSWITHdeaa310b.^ORfqdnSTARTSWITHdeaa310b.' --data-urlencode 'sysparm_fields=sys_id,name,fqdn,sys_class_name,support_group,service,business_service' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/cmdb_ci" --data-urlencode 'sysparm_query=nameLIKEDEA10B01' --data-urlencode 'sysparm_fields=sys_id,name,sys_class_name,support_group,service,business_service' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/cmdb_ci_service" --data-urlencode 'sysparm_query=assignment_group=5223d8c61b8f3c54688064e4604bcb12^ORsupport_group=5223d8c61b8f3c54688064e4604bcb12' --data-urlencode 'sysparm_fields=sys_id,name,number,operational_status,sys_class_name' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/cmdb_ci_service" --data-urlencode 'sysparm_query=nameLIKEOracle^nameLIKEAcceptance' --data-urlencode 'sysparm_fields=sys_id,name,number,assignment_group' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/cmdb_ci_service" --data-urlencode 'sysparm_query=nameLIKEOracle^nameLIKEAP-SOUTHEAST' --data-urlencode 'sysparm_fields=sys_id,name,number,assignment_group' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/cmdb_ci_service" --data-urlencode 'sysparm_query=nameLIKEALJ' --data-urlencode 'sysparm_fields=sys_id,name,number,assignment_group' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/sys_choice" --data-urlencode 'sysparm_query=name=service_offering^element=u_environment' --data-urlencode 'sysparm_fields=label,value' | jq
mkdir -p "/Users/k/Work/AIProjects/Files/2026-09-30" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-09-30"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-30/3-extract-v4-business-service-and-group" "/Users/k/Work/AIProjects/Files/2026-09-30/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-30/3-extract-v4-business-service-and-group" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-09-30/"
# Do NOT push app/Adocs: the workflow YAML contains the SNOW password
# git -C /Users/k/Codes/Pra/P1GithubActions/P1Gactions status
