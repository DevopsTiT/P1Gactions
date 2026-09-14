ls "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-13/4-snow-pd-workflow-yaml-and-json"
rg -n "correlation_id|dedup_key|cross-link" "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-13/4-snow-pd-workflow-yaml-and-json/ago-problem-to-snow-pagerduty.workflow-template.yaml"
rg -n "correlation_id|dedup_key|resolve" "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-13/4-snow-pd-workflow-yaml-and-json/ago-problem-closed-resolve-snow-pd.workflow-template.yaml"
echo "Upload create YAML/JSON once, then close YAML/JSON once — do not merge into one import file"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-13/10-snow-pd-keep-in-sync"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: explain ServiceNow PagerDuty sync via Problem ID keys"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
