# Result

| Step | Do this |
|---|---|
| 1 | Run `check.dql` query 1 to find the bucket and sources |
| 2 | Run query 2 to see whether lines are duplicated |
| 3 | Fill in the email recipients from the Splunk "Send email" action |
| 4 | Apply `main.tf` (1 detector, 1 email workflow) |
| 5 | Pick a routing option so SILVA and PagerDuty get the problem |
| 6 | Disable both Splunk alerts once Dynatrace has paged correctly in a test |
