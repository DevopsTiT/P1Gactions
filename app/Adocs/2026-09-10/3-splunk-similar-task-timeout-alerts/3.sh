# Similar Splunk Task Timed Out alerts — review before run
echo "DIR=/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-10/3-splunk-similar-task-timeout-alerts"
echo "cp \"\$DIR/terraform.tfvars.example\" \"\$DIR/terraform.tfvars\""
echo "# set pagerduty_integration_key (do not commit)"
echo "cd \"\$DIR\" && terraform init && terraform plan"
echo "# use alerting_task_timed_out_all.tf OR copy alerts/*.tf into your Splunk TF stack"
