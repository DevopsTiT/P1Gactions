cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/29-datalake-batch-result-transfer"
terraform init
terraform validate
terraform plan
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/29-datalake-batch-result-transfer" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/29-datalake-batch-result-transfer" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/29-datalake-batch-result-transfer/*.md app/Adocs/2026-10-05/29-datalake-batch-result-transfer/*.txt app/Adocs/2026-10-05/29-datalake-batch-result-transfer/*.tf app/Adocs/2026-10-05/29-datalake-batch-result-transfer/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: Datalake batch result report as Dynatrace scheduled workflow"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
