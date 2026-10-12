# EOPT Serverless Two Alerts Result

Use `8-eopt-serverless-two-alerts-tf.tf`.

| Alert | Window | Output | Severity | PagerDuty |
|---|---|---|---|---|
| E-Tool Error Lambda | 5 minutes | timestamp, loglevel, content | medium | off |
| eopt - AWS Serverless Error | 24 hours | all fields | medium | off |

| Step | Why |
|---|---|
| Run the check queries | Confirm log groups and noise. |
| Decide whether Alert 2 becomes a scheduled workflow | It duplicates Alert 1 as a detector. |
| Set up email in the workflow | Detectors do not send email. |
| Run `terraform validate` and `terraform plan` from `8.sh` | Checks the file before apply. |
