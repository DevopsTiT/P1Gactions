cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/38-all-alerts-combined-terraform"
export TF_VAR_cdus_pagerduty_routing_key="<from secret store>"
export TF_VAR_bre_pagerduty_routing_key="<from secret store>"
terraform fmt -check
terraform init
terraform validate
terraform plan
rg -n '^resource ' 38-all-alerts-combined-terraform.tf
rg -n 'CONFIRM' 38-all-alerts-combined-terraform.tf
rg -n 'arrayMovingMax' 38-all-alerts-combined-terraform.tf
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/38-all-alerts-combined-terraform" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/38-all-alerts-combined-terraform" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/38-all-alerts-combined-terraform/*.md app/Adocs/2026-10-05/38-all-alerts-combined-terraform/*.txt app/Adocs/2026-10-05/38-all-alerts-combined-terraform/*.tf
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: one Terraform file for all Dynatrace alerts written on 2026-10-05"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
