# PMT API Nine Alerts Result

Use `15-pmt-api-nine-alerts-tf.tf`.

| Step | Why |
|---|---|
| Keep the Alert 2 fix | The old parse never produced a number. |
| Delete `pmt_api_exception_myaxa_mail_sender` from the map | Duplicate of Alert 7. |
| Run query 3; fix Alert 9 spelling if needed | Otherwise it may never fire. |
| Set up email in the workflow | Detectors do not send email. |
| Run `terraform validate` and `terraform plan` from `15.sh` | Checks the file before apply. |
