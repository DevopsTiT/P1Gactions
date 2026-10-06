cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/5-emma-be-timeout-three-alerts-one-tf"
terraform init
terraform validate
terraform plan
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/5-emma-be-timeout-three-alerts-one-tf" "/Users/k/Work/AIProjects/Files/2026-10-07/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/5-emma-be-timeout-three-alerts-one-tf" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-07/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-07/5-emma-be-timeout-three-alerts-one-tf/*.md app/Adocs/2026-10-07/5-emma-be-timeout-three-alerts-one-tf/*.txt app/Adocs/2026-10-07/5-emma-be-timeout-three-alerts-one-tf/*.tf app/Adocs/2026-10-07/5-emma-be-timeout-three-alerts-one-tf/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: consolidate three Emma BE timeout Splunk alerts into one Dynatrace detector"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
