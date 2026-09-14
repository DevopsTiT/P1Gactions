echo "Open Dynatrace → Settings → Problem notifications → silvastg"
echo "Settings → External requests → add silvastg.service-now.com and events.pagerduty.com"
echo "Workflows → Upload ago-problem-to-pagerduty-only.workflow-template.yaml"
echo "Workflows → Upload ago-problem-closed-resolve-pagerduty-only.workflow-template.yaml"
echo "Replace __PD_ROUTING_KEY__ in both → Save → Activate"
echo "YAML folder: /Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-14/8-snow-classic-notification-yaml-json"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-14/9-set-workflow-ui-step-by-step"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: UI step-by-step for PD workflow with classic SNOW"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
