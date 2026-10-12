# CDUS Document Upload Five Alerts Result

Use `7-cdus-document-upload-five-alerts-tf.tf`. All five: 15-minute window, severity high, PagerDuty on.

| Step | Why |
|---|---|
| Run the five check queries | Confirm log groups and false-positive risk. |
| Keep only one of Alert 1 and Alert 5 | They are identical. |
| Fix Alert 2 if query 3 shows normal lines | Otherwise it pages on successful uploads. |
| Change Alert 3 to "ETIMEDOUT" if query 4 shows noise | Avoids matching "dateTime". |
| Rotate the PagerDuty key if the old file was committed | It was in plain text. |
| Run `terraform validate` and `terraform plan` from `7.sh` | Checks the file before apply. |
