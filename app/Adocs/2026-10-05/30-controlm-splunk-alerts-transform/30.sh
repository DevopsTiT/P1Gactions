cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/30-controlm-splunk-alerts-transform"
terraform init
terraform validate
terraform plan
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/30-controlm-splunk-alerts-transform" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/30-controlm-splunk-alerts-transform" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/30-controlm-splunk-alerts-transform/*.md app/Adocs/2026-10-05/30-controlm-splunk-alerts-transform/*.txt app/Adocs/2026-10-05/30-controlm-splunk-alerts-transform/*.tf app/Adocs/2026-10-05/30-controlm-splunk-alerts-transform/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: Control-M Splunk alerts as Dynatrace detector and workflows"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
