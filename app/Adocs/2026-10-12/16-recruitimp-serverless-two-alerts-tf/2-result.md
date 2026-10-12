# Recruitimp Serverless Two Alerts Result

Use `16-recruitimp-serverless-two-alerts-tf.tf`.

| Alert | Window | Filter | Severity | PagerDuty |
|---|---|---|---|---|
| recrutimp - AWS Serverless Error | 24 hours | level:ERROR | medium | off |
| RI Monitoring Error | 5 minutes | ERROR anywhere | medium | off |

| Step | Why |
|---|---|
| Run the check queries | Confirm log groups and Alert 2 noise. |
| Decide whether Alert 1 becomes an 08:00 workflow | It overlaps Alert 2 as a detector. |
| Set up email in the workflow | Detectors do not send email. |
| Run `terraform validate` and `terraform plan` from `16.sh` | Checks the file before apply. |
