# Compass BigData Glue Skip Investigation

| Check | Finding |
|---|---|
| Resource type | `dynatrace_log_alert` does not exist in the provider. |
| Description | `"Optional"` placeholder. |
| Query | Valid DQL filters; no time range. Old range was 5 minutes. |
| Schedule | Every 5 minutes, expires 2400. Not used by a Records detector. |
| Throttle | Off. |
| Actions | Email only, priority Normal (2 recipients, not copied). No problem or PagerDuty action. |
