export SN="https://silvastg.service-now.com"
export SNAUTH='Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}'
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/incident?sysparm_query=number%3DINC30341416&sysparm_fields=number,caller_id,u_on_behalf_of,company,assignment_group,u_business_service,cmdb_ci,u_configuration_item,u_environment,correlation_id,state,incident_state,close_code&sysparm_display_value=all&sysparm_exclude_reference_link=true"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/cmdb_ci?sysparm_query=fqdn%3Dts12.hk.intraxa%5EORname%3Dts12&sysparm_fields=sys_id,name,fqdn,sys_class_name,support_group,company&sysparm_display_value=all&sysparm_limit=5"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/service_offering?sysparm_query=sys_idSTARTSWITHcfbf255f&sysparm_fields=sys_id,name,u_environment,parent,sys_class_name&sysparm_display_value=all&sysparm_limit=1"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/cmdb_ci_service?sysparm_query=sys_idSTARTSWITH37273dbc%5Esys_class_name!%3Dservice_offering&sysparm_fields=sys_id,name,number,assignment_group,support_group,company,business_criticality&sysparm_display_value=all&sysparm_limit=1"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/sys_user?sysparm_query=sys_id%3D8ddef691fb34cf547b0dfe7b4eefdcbc&sysparm_fields=sys_id,name,user_name&sysparm_limit=1"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/sys_user_group?sysparm_query=name%3DOps_Middleware_Monitoring_AXAJP&sysparm_fields=sys_id,name,company&sysparm_display_value=all&sysparm_limit=1"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/sys_dictionary?sysparm_query=name%3Dincident%5Eelement%3Dcmdb_ci%5EORelement%3Du_configuration_item%5EORelement%3Du_business_service%5EORelement%3Dbusiness_service&sysparm_fields=element,column_label,reference,internal_type&sysparm_display_value=all"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/50-silva-cmdb-ci-sysid-explained" "/Users/k/Work/AIProjects/Files/2026-10-01/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/50-silva-cmdb-ci-sysid-explained" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-01/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-01/50-silva-cmdb-ci-sysid-explained/*.md app/Adocs/2026-10-01/50-silva-cmdb-ci-sysid-explained/*.txt
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: silva cmdb_ci and sys_id explained"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
