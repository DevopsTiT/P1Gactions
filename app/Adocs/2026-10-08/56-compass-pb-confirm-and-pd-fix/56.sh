cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/56-compass-pb-confirm-and-pd-fix"
terraform init
terraform validate
terraform plan
terraform apply
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/21-cci-goal-management-urlcheck-ng-tf"
terraform state list
terraform plan -destroy -target=dynatrace_davis_anomaly_detectors.cci_goal_management_urlcheck_ng
terraform destroy -target=dynatrace_davis_anomaly_detectors.cci_goal_management_urlcheck_ng
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-08/56-compass-pb-confirm-and-pd-fix
git commit -m "Confirm CompassPB detector; restore PagerDuty on AG Portal NTTGW and Banca Portal (supersedes seq 52/53)"
git push
