cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-06/8-esg-emma-be-timeout-alert-tf"
terraform init
terraform validate
terraform plan
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-06/8-esg-emma-be-timeout-alert-tf" "/Users/k/Work/AIProjects/Files/2026-10-06/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-06/8-esg-emma-be-timeout-alert-tf" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-06/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-06/8-esg-emma-be-timeout-alert-tf/*.md app/Adocs/2026-10-06/8-esg-emma-be-timeout-alert-tf/*.txt app/Adocs/2026-10-06/8-esg-emma-be-timeout-alert-tf/*.tf app/Adocs/2026-10-06/8-esg-emma-be-timeout-alert-tf/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: ESG Emma BE timeout Splunk alert as Dynatrace Records detector"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
