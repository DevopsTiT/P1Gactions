# HPM CMX To SharePoint Lambda Error Investigation

| Check | Finding |
|---|---|
| Resource type | `dynatrace_log_alert` does not exist in the provider. |
| Query | Valid DQL filters; no time range. Old range was 60 minutes. |
| "Error" filter | Case-insensitive, so it may match harmless lines. |
| Schedule | Hourly cron, expires 7. Not used by a Records detector. |
| Throttle | 60 minutes. Replaced by the identity field. |
| Problem action | Severity MEDIUM. |
| PagerDuty | No PagerDuty action in the file. |
| Email | 3 recipients (not copied). |
