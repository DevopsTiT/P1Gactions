cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/20-sa-support-batches-alerts-tf-check"
terraform init
terraform validate
terraform plan
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/20-sa-support-batches-alerts-tf-check" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/20-sa-support-batches-alerts-tf-check" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/20-sa-support-batches-alerts-tf-check/*.md app/Adocs/2026-10-05/20-sa-support-batches-alerts-tf-check/*.txt app/Adocs/2026-10-05/20-sa-support-batches-alerts-tf-check/*.tf app/Adocs/2026-10-05/20-sa-support-batches-alerts-tf-check/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: check of sa-support-batches alerts Terraform"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
