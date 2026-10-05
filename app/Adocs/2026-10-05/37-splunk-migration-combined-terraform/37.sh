cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/37-splunk-migration-combined-terraform"
terraform fmt -check
terraform init
terraform validate
terraform plan
rg -n '^resource ' 37-splunk-migration-combined-terraform.tf
rg -n 'CONFIRM' 37-splunk-migration-combined-terraform.tf
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/37-splunk-migration-combined-terraform" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/37-splunk-migration-combined-terraform" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/37-splunk-migration-combined-terraform/*.md app/Adocs/2026-10-05/37-splunk-migration-combined-terraform/*.txt app/Adocs/2026-10-05/37-splunk-migration-combined-terraform/*.tf
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: combined Terraform for all Splunk alerts migrated on 2026-10-05"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
