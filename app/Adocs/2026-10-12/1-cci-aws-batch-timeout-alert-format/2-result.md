# CCI AWS Batch Timeout Result

## Outcome

The file is not a valid Dynatrace Terraform resource. Use `1-cci-aws-batch-timeout-alert-format-fixed.tf`, which keeps the same search and turns it into a Records detector.

## What to do

| Step | Why |
|---|---|
| Replace the file with the fixed `.tf` | The old resource type cannot be applied. |
| Run the two queries in `1-cci-aws-batch-timeout-alert-format-check.dql` | Confirms `aws.log_group` exists and shows past timeouts. |
| Keep the old file out of Git | It contains the PagerDuty key and email addresses. |
| Rotate the PagerDuty key if the old file was pushed or shared | Anyone with the key can open incidents. |
| Configure email in the workflow | A detector does not send email itself. |
| Run `terraform validate` and `terraform plan` from `1.sh` | Checks the file before apply. |
