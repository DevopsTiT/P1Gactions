cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/11-datalake-batch-result-records-tf"
terraform init
terraform validate
terraform plan
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/11-datalake-batch-result-records-tf" "/Users/k/Work/AIProjects/Files/2026-10-07/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-07/11-datalake-batch-result-records-tf" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-07/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-07/11-datalake-batch-result-records-tf/*.md app/Adocs/2026-10-07/11-datalake-batch-result-records-tf/*.txt app/Adocs/2026-10-07/11-datalake-batch-result-records-tf/*.tf app/Adocs/2026-10-07/11-datalake-batch-result-records-tf/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: Datalake batch result as Dynatrace Records detector with real batch steps"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
