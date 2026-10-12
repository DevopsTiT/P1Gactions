# Emma MsgBox Errors Investigation

| Check | Finding |
|---|---|
| Resource type | `dynatrace_log_alert` does not exist in the provider. |
| Log group filter | Two `contains()` checks; the shorter covers the longer. |
| Status filter | "error" or "warn", case-insensitive. |
| Exclusion | "DeprecationWarning". |
| Threshold | GREATER_THAN 5, unlike earlier alerts (0). |
| Schedule | Every 5 minutes, last 5 minutes, expires 24, no throttle. |
| Problem action | Severity MEDIUM. |
| PagerDuty | None. |
| Email | 3 recipients, one is a Teams channel address (not copied). |
