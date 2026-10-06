cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/4-emma-be-timeout-esg-high-tf"
terraform init
terraform validate
terraform plan
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/4-emma-be-timeout-esg-high-tf" "/Users/k/Work/AIProjects/Files/2026-10-07/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/4-emma-be-timeout-esg-high-tf" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-07/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-07/4-emma-be-timeout-esg-high-tf/*.md app/Adocs/2026-10-07/4-emma-be-timeout-esg-high-tf/*.txt app/Adocs/2026-10-07/4-emma-be-timeout-esg-high-tf/*.tf app/Adocs/2026-10-07/4-emma-be-timeout-esg-high-tf/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: Emma BE timeout to ESG High alert as Dynatrace Records detector with PagerDuty"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
