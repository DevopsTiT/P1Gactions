cd /path/to/dynatrace-terraform/applications/G/configuration && rg -n 'variable "network_bucket_pattern"|variable "ldap_alert_email_to"|ldap_name|ldap_filter' .
cd /path/to/dynatrace-terraform/applications/G/configuration && terraform validate
cd /path/to/dynatrace-terraform/applications/G/configuration && terraform plan
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/22-terraform-variables-inside-resource" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/22-terraform-variables-inside-resource" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/22-terraform-variables-inside-resource/*.md app/Adocs/2026-10-05/22-terraform-variables-inside-resource/*.txt app/Adocs/2026-10-05/22-terraform-variables-inside-resource/*.tf
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: Terraform variables cannot be nested in resources"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
