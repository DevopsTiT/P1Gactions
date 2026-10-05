# Investigation

| What was checked | Finding |
|---|---|
| Resource | `dynatrace_log_alert` "bre_alert_innorules", not a real resource |
| Query | innorules-prod log group, contains ERROR, parse log level, level == ERROR |
| Schedule | `*/5 1-5 * * *`: every 5 minutes, only during hours 1 to 5 |
| Throttle | Disabled, so it would page every 5 minutes during an outage |
| Action | PagerDuty, integration key hard-coded on line 37 |
| Name | "BRE alert" does not follow the Prod_Life naming used elsewhere |
