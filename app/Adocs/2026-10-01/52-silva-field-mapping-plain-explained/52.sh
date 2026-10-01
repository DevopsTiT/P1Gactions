export SN="https://silvastg.service-now.com"
export SNAUTH='Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}'
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/incident?sysparm_query=number%3DINC30341416&sysparm_fields=number,u_configuration_item,cmdb_ci,u_business_service,company,assignment_group,u_environment,correlation_id&sysparm_display_value=all&sysparm_exclude_reference_link=true"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/cmdb_ci?sysparm_query=fqdn%3Dts12.hk.intraxa%5EORname%3Dts12&sysparm_fields=sys_id,name,fqdn,sys_class_name,support_group,company&sysparm_display_value=all&sysparm_limit=5"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/incident?sysparm_query=u_configuration_item%3D<TS12_SYS_ID>%5Ecmdb_ciISNOTEMPTY%5EORDERBYDESCsys_created_on&sysparm_fields=number,cmdb_ci,u_business_service&sysparm_display_value=all&sysparm_limit=20"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/service_offering?sysparm_query=sys_idSTARTSWITHcfbf255f&sysparm_fields=sys_id,name,parent,u_environment&sysparm_display_value=all&sysparm_limit=1"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/cmdb_ci_service?sysparm_query=sys_idSTARTSWITH37273dbc&sysparm_fields=sys_id,name,company,assignment_group,support_group&sysparm_display_value=all&sysparm_limit=1"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/52-silva-field-mapping-plain-explained" "/Users/k/Work/AIProjects/Files/2026-10-01/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/52-silva-field-mapping-plain-explained" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-01/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-01/52-silva-field-mapping-plain-explained/*.md app/Adocs/2026-10-01/52-silva-field-mapping-plain-explained/*.txt
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: silva field mapping plain explained"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
