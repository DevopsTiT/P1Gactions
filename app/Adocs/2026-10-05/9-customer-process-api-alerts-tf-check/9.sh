cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/9-customer-process-api-alerts-tf-check"
terraform init
terraform validate
terraform plan
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/9-customer-process-api-alerts-tf-check" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/9-customer-process-api-alerts-tf-check" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/9-customer-process-api-alerts-tf-check/*.md app/Adocs/2026-10-05/9-customer-process-api-alerts-tf-check/*.txt app/Adocs/2026-10-05/9-customer-process-api-alerts-tf-check/*.tf
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: check of customer process API alerts Terraform"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
