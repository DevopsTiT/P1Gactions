cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/32-iwfm-splunk-alerts-transform"
terraform state list
terraform plan -destroy -target='dynatrace_davis_anomaly_detectors.iwfm'
terraform destroy -target='dynatrace_davis_anomaly_detectors.iwfm'
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/69-iwfm-three-alerts-records-tf"
terraform init
terraform validate
terraform plan
terraform apply
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-08/69-iwfm-three-alerts-records-tf
git commit -m "IWFM alerts: move EIP006, Compass IWFMReportException and IWFM_Errors to Records detectors"
git push
