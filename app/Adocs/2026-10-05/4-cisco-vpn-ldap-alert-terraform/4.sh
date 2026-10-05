cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/4-cisco-vpn-ldap-alert-terraform"
cp 4-cisco-vpn-ldap-alert-terraform.tfvars.example terraform.tfvars
export DT_ENV_URL=https://<env-id>.apps.dynatrace.com
export DT_PLATFORM_TOKEN=<platform-token>
terraform init
terraform fmt 4-cisco-vpn-ldap-alert-terraform-main.tf
terraform validate
terraform plan -var-file=terraform.tfvars
terraform apply -var-file=terraform.tfvars
terraform-provider-dynatrace -export dynatrace_davis_anomaly_detectors
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/4-cisco-vpn-ldap-alert-terraform" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/4-cisco-vpn-ldap-alert-terraform" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/4-cisco-vpn-ldap-alert-terraform/*.md app/Adocs/2026-10-05/4-cisco-vpn-ldap-alert-terraform/*.txt app/Adocs/2026-10-05/4-cisco-vpn-ldap-alert-terraform/*.tf
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: Terraform for Cisco VPN LDAP Dynatrace alert"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
