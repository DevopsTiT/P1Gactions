export SN="https://silvastg.service-now.com"
export SNAUTH='Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}'
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/incident?sysparm_query=number%3DINC30341416&sysparm_fields=assignment_group,u_business_service,cmdb_ci,u_configuration_item,company,u_environment&sysparm_display_value=all&sysparm_exclude_reference_link=true"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/sys_dictionary?sysparm_query=name%3Dincident%5EelementIN%3Dassignment_group,u_business_service,cmdb_ci,u_configuration_item,company,u_environment&sysparm_fields=element,column_label,reference,internal_type&sysparm_display_value=all"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/53-silva-table-vs-incident-field" "/Users/k/Work/AIProjects/Files/2026-10-01/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/53-silva-table-vs-incident-field" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-01/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-01/53-silva-table-vs-incident-field/*.md app/Adocs/2026-10-01/53-silva-table-vs-incident-field/*.txt
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: silva table vs incident field"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
