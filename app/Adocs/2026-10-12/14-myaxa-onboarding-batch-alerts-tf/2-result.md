# MyAXA Onboarding Batch Alerts Result

Use `14-myaxa-onboarding-batch-alerts-tf.tf` for Alerts 1 to 4.

| Alert | Filter | Status |
|---|---|---|
| 1 | `sendNotifications :: error` | Ready |
| 2 | `handleOnboardedCustomers :: error` | Ready |
| 3 | `sendNotificationsQueueConsumer :: email sending failed` | Ready |
| 4 | Same text as Alert 3 | Probably needs "message sending failed" |
| 5 | Unknown | Needs screenshot |

| Step | Why |
|---|---|
| Run query 3 | Fix Alert 4's text. |
| Send Alert 5 screenshot | Finish the file. |
| Decide on PagerDuty | Names say "_High". |
| Run `terraform validate` and `terraform plan` from `14.sh` | Checks the file before apply. |
