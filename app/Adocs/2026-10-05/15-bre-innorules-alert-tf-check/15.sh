cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/15-bre-innorules-alert-tf-check"
export TF_VAR_bre_pagerduty_routing_key="<bre-pagerduty-routing-key-from-secret-store>"
terraform init
terraform validate
terraform plan
cd /path/to/dynatrace-terraform && git log --oneline -- applications/G/configuration/innorules.tf
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/15-bre-innorules-alert-tf-check" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/15-bre-innorules-alert-tf-check" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/15-bre-innorules-alert-tf-check/*.md app/Adocs/2026-10-05/15-bre-innorules-alert-tf-check/*.txt app/Adocs/2026-10-05/15-bre-innorules-alert-tf-check/*.tf app/Adocs/2026-10-05/15-bre-innorules-alert-tf-check/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: check of BRE InnoRules alert Terraform"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
