cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/2-pis-connection-esg120-alert-tf"
terraform init
terraform validate
terraform plan
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/2-pis-connection-esg120-alert-tf" "/Users/k/Work/AIProjects/Files/2026-10-07/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/2-pis-connection-esg120-alert-tf" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-07/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-07/2-pis-connection-esg120-alert-tf/*.md app/Adocs/2026-10-07/2-pis-connection-esg120-alert-tf/*.txt app/Adocs/2026-10-07/2-pis-connection-esg120-alert-tf/*.tf app/Adocs/2026-10-07/2-pis-connection-esg120-alert-tf/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: PIS ESG120 connection Splunk alert as Dynatrace Records detector"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
