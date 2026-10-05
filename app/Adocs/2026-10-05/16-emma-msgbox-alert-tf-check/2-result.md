# Result

| Step | Do this |
|---|---|
| 1 | Run `noise-check.dql` to see how often it would fire |
| 2 | Replace the resource with the detector (rolling 5-minute sum, threshold 5, dealerting 5) |
| 3 | Make both `contains` checks case-insensitive |
| 4 | Add the email workflow; no PagerDuty |
| 5 | `terraform validate` and `plan` |
