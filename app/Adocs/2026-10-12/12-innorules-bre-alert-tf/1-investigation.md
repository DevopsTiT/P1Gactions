# InnoRules BRE Alert Investigation

| Check | Finding |
|---|---|
| Resource type | `dynatrace_log_alert` does not exist in the provider. |
| Log group filter | Two `contains()` checks; the shorter covers the longer. |
| Content filter | "ERROR", case-insensitive. |
| Schedule | `*/5 1-5 * * *`: only hours 1 to 5. Timezone not stated. |
| Actions | PagerDuty only (key not copied). No email, no problem action. |
| PagerDuty key | Looks the same as the CCI timeout alert's key. |
