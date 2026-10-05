cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/5-compass-glue-skip-alert-tf-review"
terraform init
terraform validate
terraform plan
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/5-compass-glue-skip-alert-tf-review" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/5-compass-glue-skip-alert-tf-review" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/5-compass-glue-skip-alert-tf-review/*.md app/Adocs/2026-10-05/5-compass-glue-skip-alert-tf-review/*.txt app/Adocs/2026-10-05/5-compass-glue-skip-alert-tf-review/*.tf
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: review of Compass Glue skip alert Terraform"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
