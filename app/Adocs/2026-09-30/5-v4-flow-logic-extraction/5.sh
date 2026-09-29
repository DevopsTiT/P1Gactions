SNOW_USER='Tech_DynatraceJP_WS'
SNOW_PASS='<password>'
SNOW='https://silvastg.service-now.com'
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/sys_user_group" --data-urlencode 'sysparm_query=name=Database_AXAJP^active=true' --data-urlencode 'sysparm_fields=sys_id,name' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/cmdb_ci" --data-urlencode 'sysparm_query=name=deaa310b^ORnameSTARTSWITHdeaa310b.^ORfqdnSTARTSWITHdeaa310b.' --data-urlencode 'sysparm_fields=sys_id,name,fqdn,sys_class_name,service,business_service' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/cmdb_ci" --data-urlencode 'sysparm_query=nameLIKEDEA10B01' --data-urlencode 'sysparm_fields=sys_id,name,sys_class_name,service,business_service' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/svc_ci_assoc" --data-urlencode 'sysparm_query=ci_id=<CI_SYS_ID>' --data-urlencode 'sysparm_fields=service_id' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/cmdb_rel_ci" --data-urlencode 'sysparm_query=child=<CI_SYS_ID>' --data-urlencode 'sysparm_fields=parent,parent.sys_class_name,type' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/cmdb_ci_service" --data-urlencode 'sysparm_query=assignment_group=5223d8c61b8f3c54688064e4604bcb12^ORsupport_group=5223d8c61b8f3c54688064e4604bcb12' --data-urlencode 'sysparm_fields=sys_id,name,number' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/cmdb_ci_service" --data-urlencode 'sysparm_query=nameLIKEOracle^nameLIKEAcceptance' --data-urlencode 'sysparm_fields=sys_id,name,number' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/cmdb_ci_service" --data-urlencode 'sysparm_query=nameLIKEOracle^nameLIKEAP-SOUTHEAST' --data-urlencode 'sysparm_fields=sys_id,name,number' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/cmdb_ci_service" --data-urlencode 'sysparm_query=nameLIKEALJ' --data-urlencode 'sysparm_fields=sys_id,name,number' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/service_offering" --data-urlencode 'sysparm_query=parent=<SERVICE_SYS_ID>' --data-urlencode 'sysparm_fields=sys_id,name,u_environment' --data-urlencode 'sysparm_display_value=true' | jq
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-30/5-v4-flow-logic-extraction" "/Users/k/Work/AIProjects/Files/2026-09-30/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-30/5-v4-flow-logic-extraction" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-09-30/"
