# Result

| Step | Do this |
|---|---|
| 1 | Alert 1: scheduled workflow at 10:00 Asia/Tokyo, DQL count over 24 hours, email only when above 0 |
| 2 | Confirm the old Splunk time zone for 10:00 |
| 3 | Alert 2: anomaly detector, window 5, dealerting 60, `caseSensitive: false` |
| 4 | Alert 2 email: workflow on the problem name |
| 5 | Run the "error" grouping query; narrow the filter if noisy |
| 6 | Build one email task in the UI and export it to confirm the input field names |
| 7 | `terraform validate` and `plan` |
