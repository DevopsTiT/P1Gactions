cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/16-emma-msgbox-alert-tf-check"
terraform init
terraform validate
terraform plan
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/16-emma-msgbox-alert-tf-check" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/16-emma-msgbox-alert-tf-check" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/16-emma-msgbox-alert-tf-check/*.md app/Adocs/2026-10-05/16-emma-msgbox-alert-tf-check/*.txt app/Adocs/2026-10-05/16-emma-msgbox-alert-tf-check/*.tf app/Adocs/2026-10-05/16-emma-msgbox-alert-tf-check/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: check of Emma MsgBox alert Terraform"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
