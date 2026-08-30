# Review before run. Replace STG_URL / tags. Never point at production.
echo "Open Dynatrace STG environment and create dashboard L1-Health-STG"
echo "Confirm management zone or filter uses tag env:stg"
curl -sS -o /dev/null -w "%{http_code} %{time_total}\n" "https://STG_URL/health"
for i in 1 2 3 4 5 6 7 8 9 10; do curl -sS -o /dev/null -w "%{http_code}\n" "https://STG_URL/api/demo"; done
curl -sS -o /dev/null -w "%{http_code}\n" "https://STG_URL/api/demo?force_error=1"
echo "In Dynatrace UI: create HTTP synthetic monitor against https://STG_URL/health"
echo "In Dynatrace UI: verify OneAgent on STG host shows CPU memory disk"
echo "Inject STG-only failure: stop demo process or scale replicas to 0"
echo "Wait 15+ minutes once to validate Active Problems duration tile"
echo "Mark each section in 8-dynatrace-dashboard-stg-dummy-tile-checklist.yaml"
echo "Export L1-Health-STG dashboard JSON after checklist is all pass"
echo "Clone dashboard and retarget management zone to prod only after STG pass"
ls "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/8-dynatrace-dashboard-stg-dummy"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/8-dynatrace-dashboard-stg-dummy/." "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-31/8-dynatrace-dashboard-stg-dummy/"
cd "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" && git status
cd "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" && git add "app/Adocs/2026-08-31/8-dynatrace-dashboard-stg-dummy"
cd "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" && git commit -m "docs: add Dynatrace STG dummy dashboard trial plan"
cd "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" && git push
