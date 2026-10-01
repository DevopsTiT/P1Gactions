export SN="https://silvastg.service-now.com"
export SNAUTH='Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}'
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/sys_user_group?sysparm_query=name%3DInfraSupport_Dist-WindowsHK_L2_ASIA%5Eactive%3Dtrue&sysparm_fields=sys_id,name,company&sysparm_display_value=all&sysparm_limit=1"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/cmdb_ci?sysparm_query=fqdn%3Dts12.hk.intraxa%5EORname%3Dts12%5EORname%3Dts12.hk.intraxa&sysparm_fields=sys_id,name,fqdn,sys_class_name,support_group,company,business_service,service&sysparm_display_value=all&sysparm_limit=5"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/svc_ci_assoc?sysparm_query=ci_id%3D<TS12_SYS_ID>&sysparm_fields=service_id&sysparm_display_value=all&sysparm_limit=5"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/incident?sysparm_query=u_configuration_item%3D<TS12_SYS_ID>%5Ecmdb_ciISNOTEMPTY%5EORDERBYDESCsys_created_on&sysparm_fields=number,cmdb_ci,u_business_service,assignment_group&sysparm_display_value=all&sysparm_limit=20"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/sys_choice?sysparm_query=name%3Dincident%5Eelement%3Du_environment%5Einactive%3Dfalse&sysparm_fields=value,label&sysparm_limit=50"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/incident?sysparm_query=correlation_id%3DP-261090&sysparm_fields=number,state,incident_state,assignment_group,u_environment,u_business_service,cmdb_ci,u_configuration_item,company,close_code&sysparm_display_value=all"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/55-p261090-real-input-walkthrough" "/Users/k/Work/AIProjects/Files/2026-10-01/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/55-p261090-real-input-walkthrough" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-01/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-01/55-p261090-real-input-walkthrough/*.md app/Adocs/2026-10-01/55-p261090-real-input-walkthrough/*.txt
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: p-261090 real input walkthrough"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
