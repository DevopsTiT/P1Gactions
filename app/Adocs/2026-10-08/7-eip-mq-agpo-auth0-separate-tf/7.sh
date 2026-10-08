cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-08/7-eip-mq-agpo-auth0-separate-tf"
terraform init
terraform validate
terraform state mv 'dynatrace_davis_anomaly_detectors.eip_agpo_alerts["eip_mq_conn_timeout"]' dynatrace_davis_anomaly_detectors.eip_mq_conn_timeout
terraform state mv 'dynatrace_davis_anomaly_detectors.eip_agpo_alerts["agpo_auth0_password_sync_error"]' dynatrace_davis_anomaly_detectors.agpo_auth0_password_sync_error
terraform plan
terraform apply
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions
git add app/Adocs/2026-10-08/7-eip-mq-agpo-auth0-separate-tf
git commit -m "Split EIP MQ and AGPO detectors into separate tf files"
git push
