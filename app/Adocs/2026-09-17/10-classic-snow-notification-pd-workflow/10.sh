echo "Keep UI: Settings → Problem notifications → servicenowstg (ITSM OFF, ITOM ON)"
echo "Optional YAML: servicenowstg-problem-notification.settings.json"
echo "Upload PD workflows: ago-problem-to-pagerduty-only + ago-problem-closed-resolve-pagerduty-only"
echo "Replace __PD_ROUTING_KEY__; allowlist events.pagerduty.com + silvastg.service-now.com"
echo "Folder: /Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-17/10-classic-snow-notification-pd-workflow"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-17/10-classic-snow-notification-pd-workflow"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: classic servicenowstg notification YAML plus PD-only workflows"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
