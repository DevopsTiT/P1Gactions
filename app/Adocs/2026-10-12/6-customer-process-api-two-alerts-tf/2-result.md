# Customer Process API Two Alerts Result

Use `6-customer-process-api-two-alerts-tf.tf`.

| Alert | Query window | Severity | PagerDuty |
|---|---|---|---|
| Success Request Monitoring | 5 minutes | low | off |
| Customer Process API Alerts | 5 minutes | medium | off |

| Step | Why |
|---|---|
| Run the three check queries | Confirm log groups, the 201 format and which messages fire. |
| Confirm `IBL0250002` | Read from a photo. |
| Set up email in the workflow | Detectors do not send email. |
| Run `terraform validate` and `terraform plan` from `6.sh` | Checks the file before apply. |
