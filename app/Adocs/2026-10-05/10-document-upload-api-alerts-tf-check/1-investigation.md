# Investigation

| What was checked | Finding |
|---|---|
| Resources | 5 `dynatrace_log_alert` blocks, not a real resource |
| Alert 1 Pending | Keeps STARTED, COMPLETED and FAILED, so it fires on every upload |
| Alert 2 Failed | Same query as Alert 1, so it also fires on every upload |
| Alert 3 Database | "Failed to init database", "ETIMEDOUT", "ECONNREFUSED" |
| Alert 4 CMX | "Failed to create CMX Document" |
| Alert 5 Batch | Worker log groups plus "Error Report" or "ExitError", throttle 8 hours |
| Parse pattern | `WORD` cuts ids at hyphens; no allowance for a space after `action:` |
| PagerDuty | Same key hard-coded in all 5, different from the SILVA workflow's key |
| Email | axa_jp_dl_new_business and axa_jp_dl_bam |
