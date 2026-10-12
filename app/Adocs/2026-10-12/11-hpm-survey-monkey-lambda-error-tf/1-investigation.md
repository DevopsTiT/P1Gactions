# HPM SurveyMonkey Lambda Error Investigation

| Check | Finding |
|---|---|
| Resource type | `dynatrace_log_alert` does not exist in the provider. |
| Query | Valid DQL filters; no time range. Old range was 60 minutes. |
| "ERROR" filter | Case-insensitive, may match normal text. |
| Schedule | Hourly, expires 7. |
| Throttle | 60 minutes. |
| Problem action | Severity MEDIUM. |
| PagerDuty | None. |
| Email | 3 recipients (not copied). |
| Description | Typos "Lamda" and "Survey money". |
