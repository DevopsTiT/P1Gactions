export SN="https://silvastg.service-now.com"
export SNAUTH='Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}'
export PID="P-261090"
export PDKEY="222651dbacb04403c0bf52d3b48499e8"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/sys_user_group?sysparm_query=name%3DOps_Middleware_Monitoring_AXAJP%5Eactive%3Dtrue&sysparm_fields=sys_id,name,company&sysparm_limit=1"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/cmdb_ci?sysparm_query=fqdn%3Dts12.hk.intraxa%5EORname%3Dts12&sysparm_fields=sys_id,name,fqdn,sys_class_name,support_group,company&sysparm_display_value=all&sysparm_limit=5"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/svc_ci_assoc?sysparm_query=ci_id%3D<CI_SYS_ID>&sysparm_fields=service_id&sysparm_display_value=all&sysparm_limit=5"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/cmdb_rel_ci?sysparm_query=child%3D<CI_SYS_ID>&sysparm_fields=parent,parent.sys_class_name,type&sysparm_display_value=all&sysparm_limit=50"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/service_offering?sysparm_query=parent%3D<SERVICE_SYS_ID>&sysparm_fields=sys_id,name,u_environment,parent&sysparm_display_value=all&sysparm_limit=50"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/incident?sysparm_query=u_configuration_item%3D<CI_SYS_ID>%5Ecmdb_ciISNOTEMPTY%5EORDERBYDESCsys_created_on&sysparm_fields=number,cmdb_ci,u_business_service&sysparm_display_value=all&sysparm_limit=20"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/incident?sysparm_query=correlation_id%3D$PID%5Eactive%3Dtrue&sysparm_fields=sys_id,number,state,incident_state,close_code&sysparm_display_value=all&sysparm_limit=5"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/sys_choice?sysparm_query=name%3Dincident%5Eelement%3Dincident_state%5Einactive%3Dfalse%5Elanguage%3Den&sysparm_fields=value,label&sysparm_limit=100"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/sys_choice?sysparm_query=name%3Dincident%5Eelement%3Dclose_code%5Einactive%3Dfalse%5Elanguage%3Den&sysparm_fields=value,label&sysparm_limit=100"
curl -s -u "$SNAUTH" -X PATCH -H "Accept: application/json" -H "Content-Type: application/json" "$SN/api/now/v2/table/incident/<INCIDENT_SYS_ID>?sysparm_display_value=all" -d '{"state":"<RESOLVED_VALUE_FROM_SYS_CHOICE>","incident_state":"<RESOLVED_VALUE_FROM_SYS_CHOICE>","close_code":"Solved (Permanently)","close_notes":"manual test close"}'
curl -s -X POST -H "Content-Type: application/json" https://events.pagerduty.com/v2/enqueue -d '{"routing_key":"'"$PDKEY"'","event_action":"trigger","dedup_key":"dt-problem-TEST-47","payload":{"summary":"E2E test 47","source":"manual","severity":"warning"}}'
curl -s -X POST -H "Content-Type: application/json" https://events.pagerduty.com/v2/enqueue -d '{"routing_key":"'"$PDKEY"'","event_action":"resolve","dedup_key":"dt-problem-TEST-47"}'
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/47-open-close-e2e-api-data-flow" "/Users/k/Work/AIProjects/Files/2026-10-01/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/47-open-close-e2e-api-data-flow" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-01/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-01/47-open-close-e2e-api-data-flow/*.md app/Adocs/2026-10-01/47-open-close-e2e-api-data-flow/*.txt
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: open and close workflows e2e api data flow"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
