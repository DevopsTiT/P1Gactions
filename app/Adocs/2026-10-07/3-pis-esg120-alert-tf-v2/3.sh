cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/3-pis-esg120-alert-tf-v2"
terraform init
terraform validate
terraform plan
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/3-pis-esg120-alert-tf-v2" "/Users/k/Work/AIProjects/Files/2026-10-07/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/3-pis-esg120-alert-tf-v2" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-07/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-07/3-pis-esg120-alert-tf-v2/*.md app/Adocs/2026-10-07/3-pis-esg120-alert-tf-v2/*.txt app/Adocs/2026-10-07/3-pis-esg120-alert-tf-v2/*.tf app/Adocs/2026-10-07/3-pis-esg120-alert-tf-v2/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: PIS ESG120 alert filtered by log path after checking real events"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
