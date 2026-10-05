# Investigation

| What was checked | Finding |
|---|---|
| Resources | 3 `dynatrace_log_alert` blocks, not real |
| Log group | `/aws/lambda/sa-support-batches-prod` for all 3 |
| Alert 1 | Lowercase "error", every 5 minutes over 6 minutes, email 2 recipients |
| Alert 2 | "importFileHandler :: runner" OR "importSagaFundGroup" OR "started", weekdays 08:30 over 24 hours, fewer than 2 results, email annuitypayment |
| Alert 3 | "Task timed out", every 5 minutes over 6 minutes, same recipients as alert 1 |
| Secrets | None |
