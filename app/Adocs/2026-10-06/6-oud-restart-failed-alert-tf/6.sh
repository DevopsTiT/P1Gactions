cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-06/6-oud-restart-failed-alert-tf"
terraform init
terraform validate
terraform plan
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-06/6-oud-restart-failed-alert-tf" "/Users/k/Work/AIProjects/Files/2026-10-06/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-06/6-oud-restart-failed-alert-tf" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-06/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-06/6-oud-restart-failed-alert-tf/*.md app/Adocs/2026-10-06/6-oud-restart-failed-alert-tf/*.txt app/Adocs/2026-10-06/6-oud-restart-failed-alert-tf/*.tf app/Adocs/2026-10-06/6-oud-restart-failed-alert-tf/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: OUD restart failed Splunk alert as Dynatrace Records detector"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
