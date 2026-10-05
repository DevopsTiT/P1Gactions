# Result

| Step | Do this |
|---|---|
| 1 | Alert 1: scheduled workflow every 5 minutes, email the 201 lines, no problem |
| 2 | Check whether logs use `"statusCode":201` or `"statusCode": 201` |
| 3 | Alert 2: anomaly detector with `lower(content)` and the 9 lower-case strings |
| 4 | Alert 2 email: workflow on the problem name |
| 5 | Compare the 9 strings with the original file |
| 6 | `terraform validate` and `plan` |
