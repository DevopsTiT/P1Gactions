# HPM SharePoint API Lambda Error Investigation

| Check | Finding |
|---|---|
| Resource type | `dynatrace_log_alert` does not exist in the provider. |
| Query | Valid DQL filters; no time range. Old range was 24 hours. |
| "ERROR" filter | Case-insensitive, may match normal text. |
| Schedule | Daily 10:00, expires 7. Cannot be kept in a detector. |
| Throttle | 60 minutes. |
| Problem action | Severity MEDIUM. |
| PagerDuty | None. |
| Email | 3 recipients (not copied). |
