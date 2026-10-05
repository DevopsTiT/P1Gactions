# Investigation

| What was checked | Finding |
|---|---|
| Alert 1 | `"statusCode":201` in customer-process-api-prod, every 5 minutes, email to 4 people |
| Alert 1 purpose | Description says it is to see real production contract requests, so it reports success |
| Alert 2 | 9 failure strings joined with `or`, every 5 minutes, email to aij_jp_dl_adept |
| Resource type | Both `dynatrace_log_alert`, not in the provider |
| Case | Splunk was case-insensitive; DQL needs `lower()` or `caseSensitive: false` |
| Secrets | None |
