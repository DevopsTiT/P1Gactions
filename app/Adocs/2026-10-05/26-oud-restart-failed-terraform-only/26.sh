cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/26-oud-restart-failed-terraform-only"
terraform init
terraform validate
terraform plan
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/26-oud-restart-failed-terraform-only" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/26-oud-restart-failed-terraform-only" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/26-oud-restart-failed-terraform-only/*.md app/Adocs/2026-10-05/26-oud-restart-failed-terraform-only/*.txt app/Adocs/2026-10-05/26-oud-restart-failed-terraform-only/*.tf
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: OUD restart failed detector Terraform"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
