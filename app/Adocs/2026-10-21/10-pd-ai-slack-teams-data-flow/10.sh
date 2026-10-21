cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-21/10-pd-ai-slack-teams-data-flow
git status -sb
git commit -m "Add PD AI Slack Teams data flow Adocs"
git push origin main
./sync-adocs-to-files.sh 2026-10-21
