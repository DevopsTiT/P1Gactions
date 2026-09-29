SNOW_USER='Tech_DynatraceJP_WS'
SNOW_PASS='<password>'
SNOW='https://silvastg.service-now.com'
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/sys_choice" --data-urlencode 'sysparm_query=name=incident^elementINstate,close_code^inactive=false' --data-urlencode 'sysparm_fields=element,label,value' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/incident" --data-urlencode 'sysparm_query=correlation_id=P-260916434' --data-urlencode 'sysparm_fields=number,sys_id,state,active,close_code,close_notes' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/incident" --data-urlencode 'sysparm_query=number=INC30340215' --data-urlencode 'sysparm_fields=number,state,close_code,close_notes,resolved_by,resolved_at' --data-urlencode 'sysparm_display_value=all' | jq
curl -s -X PATCH -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/incident/<INCIDENT_SYS_ID>" -H 'Content-Type: application/json' -d '{"state":"6","close_code":"Solved (Permanently)","close_notes":"manual test resolve","comments":"Resolved"}' | jq
curl -s -X POST https://events.pagerduty.com/v2/enqueue -H 'Content-Type: application/json' -d '{"routing_key":"<ROUTING_KEY>","event_action":"resolve","dedup_key":"dt-problem-P-260916434"}'
mkdir -p "/Users/k/Work/AIProjects/Files/2026-09-30" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-09-30"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-30/11-v6-close-silva-pagerduty" "/Users/k/Work/AIProjects/Files/2026-09-30/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-30/11-v6-close-silva-pagerduty" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-09-30/"
# Do NOT push app/Adocs: the workflow YAML contains the SNOW password and the PagerDuty routing key
