ls "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-14/3-snow-pd-workflow-with-connection"
echo "1) Create Settings → Connections → ServiceNow"
echo "2) Upload ago-problem-to-snow-pagerduty-connection.workflow-template.yaml"
echo "3) Upload ago-problem-closed-resolve-snow-pd-connection.workflow-template.yaml"
echo "4) Map Connection; replace __PD_ROUTING_KEY__ and sys_ids"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-14/3-snow-pd-workflow-with-connection"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: SNOW PD workflows using ServiceNow Connection"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
