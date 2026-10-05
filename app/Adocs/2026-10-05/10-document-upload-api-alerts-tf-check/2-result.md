# Result

| Step | Do this |
|---|---|
| 1 | Remove the PagerDuty key from the file; rotate it if it was pushed |
| 2 | Run the parse check query on a real log line |
| 3 | Alert 1: scheduled workflow with the per-document pending query and the event task |
| 4 | Alert 2: keep only `UPLOAD_FAILED` |
| 5 | Alerts 2 to 5: detectors via the `for_each` block |
| 6 | Add the CDUS routing workflow (PagerDuty plus email) |
| 7 | Decide whether CDUS problems should also create SILVA tickets |
| 8 | `terraform validate` and `plan` with the key passed from the environment |
