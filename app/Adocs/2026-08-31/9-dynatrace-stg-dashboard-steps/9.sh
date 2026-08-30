# Review before run. Replace STG_URL. Never use production URLs.
echo "Step1: In Dynatrace UI open Hosts and confirm STG host CPU memory disk"
echo "Step2: Tag STG host service process with env:stg"
echo "Step3: Create management zone MZ-STG for tag env:stg"
echo "Step4: Create dashboard L1-Health-STG default timeframe Last 2 hours"
echo "Step5: Create HTTP synthetic STG-app-health against https://STG_URL/health tag env:stg"
curl -sS -o /dev/null -w "%{http_code} %{time_total}\n" "https://STG_URL/health"
for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do curl -sS -o /dev/null -w "%{http_code}\n" "https://STG_URL/api/demo"; done
curl -sS -o /dev/null -w "%{http_code}\n" "https://STG_URL/api/demo?force_error=1"
echo "Step7: Add tiles 1-11 filtered to env:stg or MZ-STG"
echo "Step8: Inject one STG failure at a time then restore; leave one problem >15 minutes"
echo "Step9: Mark acceptance checklist all pass"
echo "Step10: Export L1-Health-STG JSON; clone to prod only later"
ls "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/9-dynatrace-stg-dashboard-steps"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-08-31/9-dynatrace-stg-dashboard-steps/." "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-08-31/9-dynatrace-stg-dashboard-steps/"
cd "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" && git status
cd "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" && git add "app/Adocs/2026-08-31/9-dynatrace-stg-dashboard-steps"
cd "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" && git commit -m "docs: add Dynatrace STG dashboard detailed steps"
cd "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" && git push
