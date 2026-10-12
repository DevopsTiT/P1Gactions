# MyAXA Onboarding Batch Five Alerts Result

Use `14-myaxa-onboarding-batch-five-alerts-tf.tf` after fixing Alerts 4 and 5.

| Alert | Suggested content filter |
|---|---|
| 4 | `contains(content, "sendNotificationsQueueConsumer :: message sending failed")` |
| 5 | `contains(content, "sendNotificationsQueueConsumer :: error")` |

| Step | Why |
|---|---|
| Run query 2 | Confirms the real message texts. |
| Fix Alerts 4 and 5 | Avoids duplicate emails and missed errors. |
| Set up email in the workflow | Detectors do not send email. |
| Run `terraform validate` and `terraform plan` from `14.sh` | Checks the file before apply. |
