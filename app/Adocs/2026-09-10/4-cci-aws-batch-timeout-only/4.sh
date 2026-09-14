# CCI_AWS_Batch Time Out only — review before run
echo "DIR=/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-10/4-cci-aws-batch-timeout-only"
echo "cp \"\$DIR/terraform.tfvars.example\" \"\$DIR/terraform.tfvars\""
echo "# set pagerduty_integration_key (do not commit)"
echo "cd \"\$DIR\" && terraform init && terraform plan"
