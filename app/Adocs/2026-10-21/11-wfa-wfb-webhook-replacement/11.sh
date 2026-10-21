mkdir -p "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-21/11-wfa-wfb-webhook-replacement"
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-21/11-wfa-wfb-webhook-replacement"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-21/11-wfa-wfb-webhook-replacement/." "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-21/11-wfa-wfb-webhook-replacement/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-21/11-wfa-wfb-webhook-replacement/." "/Users/k/Work/AIProjects/Files/2026-10-21/11-wfa-wfb-webhook-replacement/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-21/11-wfa-wfb-webhook-replacement
git status -sb
git commit -m "Add WF-A/WF-B Slack webhook replacement workflows"
git push origin main
curl -X POST -H "Content-Type: application/json" -d "{\"text\":\"WF-A webhook test\"}" "YOUR_NEW_WEBHOOK_URL_HERE"
