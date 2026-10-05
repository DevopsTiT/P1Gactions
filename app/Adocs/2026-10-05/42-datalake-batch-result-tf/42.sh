cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/42-datalake-batch-result-tf"
terraform init
terraform validate
terraform plan
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/42-datalake-batch-result-tf" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/42-datalake-batch-result-tf" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/42-datalake-batch-result-tf/*.md app/Adocs/2026-10-05/42-datalake-batch-result-tf/*.txt app/Adocs/2026-10-05/42-datalake-batch-result-tf/*.tf app/Adocs/2026-10-05/42-datalake-batch-result-tf/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: standalone Datalake batch result workflow Terraform"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
