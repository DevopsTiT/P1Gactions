curl -X POST "https://<ENV_ID>.live.dynatrace.com/api/v2/logs/ingest" -H "Authorization: Api-Token $DT_TOKEN" -H "Content-Type: application/json; charset=utf-8" --data @"/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-15/18-dynatrace-dummy-data-testing/18-dynatrace-dummy-data-testing-logs-ingest.json"
curl -X POST "https://<ENV_ID>.live.dynatrace.com/api/v2/metrics/ingest" -H "Authorization: Api-Token $DT_TOKEN" -H "Content-Type: text/plain; charset=utf-8" --data-binary "custom.dummy.cpu_usage,k8s.pod.name=pc-ui-dummy 250"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-15/18-dynatrace-dummy-data-testing
git commit -m "dynatrace dummy data testing"
git push
