cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/43-datalake-batch-result-detector"
terraform init
terraform validate
terraform plan
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/43-datalake-batch-result-detector" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/43-datalake-batch-result-detector" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/43-datalake-batch-result-detector/*.md app/Adocs/2026-10-05/43-datalake-batch-result-detector/*.txt app/Adocs/2026-10-05/43-datalake-batch-result-detector/*.tf app/Adocs/2026-10-05/43-datalake-batch-result-detector/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: Datalake batch result as a Dynatrace detector"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
