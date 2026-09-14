# Migrate CCI Splunk alert to Dynatrace TF (review before apply)
echo "DIR=/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-10/9-migrate-cci-timeout-splunk-to-dynatrace-tf"
echo "Copy alerting_cci_aws_batch_timeout_dynatrace.tf into dynatrace-terraform applications/<app>/<env>/"
echo "Set DYNATRACE_ENV_URL and DYNATRACE_API_TOKEN (settings.read/write) then terraform init && plan"
echo "After apply: wire Problem notifications to PagerDuty if needed"
