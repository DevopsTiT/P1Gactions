cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/30-controlm-splunk-alerts-transform"
terraform state list
terraform plan -destroy -target='dynatrace_automation_workflow.controlm_rerun_check'
terraform destroy -target='dynatrace_automation_workflow.controlm_rerun_check'
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/72-controlm-rerun-check-tf"
terraform init
terraform validate
terraform plan
terraform apply
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-08/72-controlm-rerun-check-tf
git commit -m "CTL-M rerun check: migrate as Records detector, identity replaces history CSV"
git push
