cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/25-oud-restart-failed-alert-transform"
terraform init
terraform validate
terraform plan
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/25-oud-restart-failed-alert-transform" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/25-oud-restart-failed-alert-transform" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/25-oud-restart-failed-alert-transform/*.md app/Adocs/2026-10-05/25-oud-restart-failed-alert-transform/*.txt app/Adocs/2026-10-05/25-oud-restart-failed-alert-transform/*.tf app/Adocs/2026-10-05/25-oud-restart-failed-alert-transform/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: OUD restart failed alert for Dynatrace"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
