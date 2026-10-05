cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/13-hpm-sharepoint-api-alert-tf-check"
terraform init
terraform validate
terraform plan
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/13-hpm-sharepoint-api-alert-tf-check" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/13-hpm-sharepoint-api-alert-tf-check" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/13-hpm-sharepoint-api-alert-tf-check/*.md app/Adocs/2026-10-05/13-hpm-sharepoint-api-alert-tf-check/*.txt app/Adocs/2026-10-05/13-hpm-sharepoint-api-alert-tf-check/*.tf
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: check of HPM SharePoint API alert Terraform"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
