# Result

| Step | Do this |
|---|---|
| 1 | Replace the resource with a detector: window 5, dealerting 60 |
| 2 | Add `caseSensitive: false` to the content filter |
| 3 | Add the email workflow; no PagerDuty |
| 4 | Fix the description typos |
| 5 | Optionally merge with the other hourly HPM alert in one `for_each` |
| 6 | `terraform validate` and `plan` |
