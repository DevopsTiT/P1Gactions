# Sa Support Batches Result

| Alert | New resource | Window | Severity | PagerDuty |
|---|---|---|---|---|
| Sa Support Batch Error | `sa_support_batch_error` | 6 minutes | medium | off |
| Sa Support Batch File Import Confirmation | `sa_support_batch_file_import_confirmation` | 24 hours, checked weekdays 08:30 JST | medium | off |
| Sa Support Batch Task Time Out | `sa_support_batch_task_timeout` | 6 minutes | medium | off |

## Next steps

| Step | Why |
|---|---|
| Run check query 2 | Find the real error text that Alert 1 should catch. |
| Fix or delete Alert 1 | Today it duplicates Alert 3. |
| Run check query 3 | See whether "started" makes Alert 2 useless. |
| Run check query 4 at 08:30 JST | Confirm the JST guard returns true. If not, use a scheduled workflow. |
| Run `terraform validate` and `plan` from `17.sh` | Confirm the HCL before applying. |
