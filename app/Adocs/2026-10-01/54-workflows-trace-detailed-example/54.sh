export DT="https://wuh86725.apps.dynatrace.com"
export DTTOKEN="__DT_PLATFORM_TOKEN__"
export SN="https://silvastg.service-now.com"
export SNAUTH='Tech_DynatraceJP_WS:JGyUG4XW^h^zCaW.U*(_Wnt0{+=XIqwNkL(pF*Z}'
curl -s -H "Authorization: Bearer $DTTOKEN" "$DT/platform/automation/v1/executions/<OPEN_EXECUTION_ID>/tasks/extract-event-tags/result"
curl -s -H "Authorization: Bearer $DTTOKEN" "$DT/platform/automation/v1/executions/<OPEN_EXECUTION_ID>/tasks/resolve-snow-values/result"
curl -s -H "Authorization: Bearer $DTTOKEN" "$DT/platform/automation/v1/executions/<OPEN_EXECUTION_ID>/tasks/build-payload/result"
curl -s -H "Authorization: Bearer $DTTOKEN" "$DT/platform/automation/v1/executions/<OPEN_EXECUTION_ID>/tasks/post-silva-incident/result"
curl -s -H "Authorization: Bearer $DTTOKEN" "$DT/platform/automation/v1/executions/<OPEN_EXECUTION_ID>/tasks/trigger-pagerduty/result"
curl -s -H "Authorization: Bearer $DTTOKEN" "$DT/platform/automation/v1/executions/<CLOSE_EXECUTION_ID>/tasks/prepare-close/result"
curl -s -H "Authorization: Bearer $DTTOKEN" "$DT/platform/automation/v1/executions/<CLOSE_EXECUTION_ID>/tasks/close-silva-incident/result"
curl -s -H "Authorization: Bearer $DTTOKEN" "$DT/platform/automation/v1/executions/<CLOSE_EXECUTION_ID>/tasks/close-pagerduty/result"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/sys_choice?sysparm_query=name%3Dincident%5Eelement%3Dstate%5Einactive%3Dfalse%5Elanguage%3Den&sysparm_fields=value,label&sysparm_limit=50"
curl -s -u "$SNAUTH" -H "Accept: application/json" "$SN/api/now/v2/table/incident?sysparm_query=number%3DINC30341416&sysparm_fields=sys_id,number,state,incident_state,close_code,correlation_id&sysparm_display_value=all"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/54-workflows-trace-detailed-example" "/Users/k/Work/AIProjects/Files/2026-10-01/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/54-workflows-trace-detailed-example" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-01/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-01/54-workflows-trace-detailed-example/*.md app/Adocs/2026-10-01/54-workflows-trace-detailed-example/*.txt
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: workflows detailed trace example"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
