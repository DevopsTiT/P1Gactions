# Gov Inquiry System Seven Alerts Result

Use `9-gov-inquiry-system-seven-alerts-tf.tf`.

| Alert | Severity | Identity | Status |
|---|---|---|---|
| 1 ND file summary | low | fileName | Ready |
| 2 answer file summary | low | fileName | Placeholder, disabled |
| 3 request file summary | low | fileName | Ready, confirm log group |
| 4 General Error | medium | aws.log_group | Ready, confirm log group |
| 5 Error File Processing | medium | aws.log_group | Ready |
| 6 System Error File Processing | medium | aws.log_group | Ready |
| 7 MDM file summary | low | aws.log_group | Ready |

| Step | Why |
|---|---|
| Send a straight screenshot of Alert 2 | Finishes the placeholder. |
| Run the check queries | Confirm log groups, file categories and file name format. |
| Set up email in the workflow | Detectors do not send email. |
| Run `terraform validate` and `terraform plan` from `9.sh` | Checks the file before apply. |
