echo "Upload OPEN: /Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-17/13-working-snow-pd-workflow-yaml/1-open-problem-to-snow-pagerduty.workflow.yaml"
echo "Upload CLOSE: /Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-17/13-working-snow-pd-workflow-yaml/2-close-problem-resolve-snow-pd.workflow.yaml"
echo "Map ServiceNow Connection; replace __PD_ROUTING_KEY__ and SNOW sys_ids; classic ITSM OFF"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-17/13-working-snow-pd-workflow-yaml"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: working SNOW+PD Dynatrace workflow YAML with ServiceNow tasks"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
