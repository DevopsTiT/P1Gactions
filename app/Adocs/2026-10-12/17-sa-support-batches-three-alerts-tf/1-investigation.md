# Sa Support Batches Investigation

| What was checked | Finding |
|---|---|
| Resource type | `dynatrace_log_alert` does not exist in the Dynatrace provider. |
| Alert 1 query | Log group sa-support-batches, "Task timed out" ignoring case, 6 minutes. |
| Alert 3 query | Exactly the same as Alert 1. |
| Alert 1 name | Says "Error" but the filter only finds timeouts. |
| Alert 2 condition | Fires when fewer than 2 matching lines in 24 hours. This is an absence check. |
| Alert 2 schedule | `30 8 * * 1-5` means 08:30 Monday to Friday. |
| Alert 2 phrases | "importFileHandler :: runner :", "importSagaFundGroup", "started". The last one is very broad. |
| Log group filters | Each alert had a long and a short log group check joined with `or`. The short one covers both. |
| Email priority | Normal on all three, so severity medium. |
| Secrets | No PagerDuty key in this file. Email recipients were not copied. |
