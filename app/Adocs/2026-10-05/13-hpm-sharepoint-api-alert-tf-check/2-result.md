# Result

| Step | Do this |
|---|---|
| 1 | Replace the resource with the daily scheduled workflow |
| 2 | Drop the 60-minute throttle and the problem action |
| 3 | Add `caseSensitive: false` to the content filter |
| 4 | Confirm the old Splunk 10:00 time zone |
| 5 | Ask the team whether a daily problem is really wanted |
| 6 | `terraform validate` and `plan` |
