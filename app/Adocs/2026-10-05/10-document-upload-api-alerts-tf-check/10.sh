rg -n "integration_key|routing_key" C:/Codes
git log --oneline -S "<first-8-chars-of-cdus-key>"
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/10-document-upload-api-alerts-tf-check"
export TF_VAR_cdus_pagerduty_routing_key=<cdus-routing-key-from-secret-store>
terraform init
terraform validate
terraform plan
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/10-document-upload-api-alerts-tf-check" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/10-document-upload-api-alerts-tf-check" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/10-document-upload-api-alerts-tf-check/*.md app/Adocs/2026-10-05/10-document-upload-api-alerts-tf-check/*.txt app/Adocs/2026-10-05/10-document-upload-api-alerts-tf-check/*.tf
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: check of document upload API alerts Terraform"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
