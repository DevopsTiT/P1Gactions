SNOW_USER='Tech_DynatraceJP_WS'
SNOW_PASS='<password>'
SNOW='https://silvastg.service-now.com'
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/incident" --data-urlencode 'sysparm_query=number=INC30340215' --data-urlencode 'sysparm_fields=caller_id,u_on_behalf_of,contact_type,company,u_environment,business_service,service_offering,cmdb_ci,category,subcategory,impact,urgency,assignment_group,correlation_id' --data-urlencode 'sysparm_display_value=all' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/incident" --data-urlencode 'sysparm_query=correlation_id=P-260916434^active=true' --data-urlencode 'sysparm_fields=number,sys_id,state,assignment_group' --data-urlencode 'sysparm_display_value=true' | jq
curl -s -G -u "$SNOW_USER:$SNOW_PASS" "$SNOW/api/now/v2/table/incident" --data-urlencode 'sysparm_query=caller_id.name=Dynatrace JP^ORDERBYDESCsys_created_on' --data-urlencode 'sysparm_fields=number,short_description,assignment_group,business_service,correlation_id,state' --data-urlencode 'sysparm_display_value=true' --data-urlencode 'sysparm_limit=5' | jq
curl -s -X POST https://events.pagerduty.com/v2/enqueue -H 'Content-Type: application/json' -d '{"routing_key":"<ROUTING_KEY>","event_action":"trigger","dedup_key":"dt-problem-TEST-1","payload":{"summary":"[DYNATRACE JAPAN] test trigger","source":"manual-test","severity":"warning"}}'
curl -s -X POST https://events.pagerduty.com/v2/enqueue -H 'Content-Type: application/json' -d '{"routing_key":"<ROUTING_KEY>","event_action":"resolve","dedup_key":"dt-problem-TEST-1"}'
mkdir -p "/Users/k/Work/AIProjects/Files/2026-09-30" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-09-30"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-30/9-v6-full-open-silva-pagerduty" "/Users/k/Work/AIProjects/Files/2026-09-30/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-30/9-v6-full-open-silva-pagerduty" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-09-30/"
# Do NOT push app/Adocs: the workflow YAML contains the SNOW password and the PagerDuty routing key
