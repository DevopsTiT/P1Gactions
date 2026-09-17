echo "Upload: /Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-17/12-working-pd-workflow-yaml/1-open-problem-to-pagerduty.workflow.yaml"
echo "Upload: /Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-17/12-working-pd-workflow-yaml/2-close-problem-resolve-pagerduty.workflow.yaml"
echo "Replace __PD_ROUTING_KEY__ in both; allowlist events.pagerduty.com; keep servicenowstg ON"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-17/12-working-pd-workflow-yaml"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: working PD-only Dynatrace workflow YAML files"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
