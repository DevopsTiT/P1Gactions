# Investigation

| What was checked | Finding |
|---|---|
| Resource | `dynatrace_log_alert` "emma_overall_msgbox_errors", not a real resource |
| Query | message-box-api-prod, content contains "error" or "warn" in lowercase |
| Case | DQL `contains` is case-sensitive by default, so uppercase lines are missed |
| Trigger | Every 5 minutes, last 5 minutes, more than 5 results, no throttle |
| Actions | Problem MEDIUM, email to a Teams channel and 2 mailboxes |
| Secrets | None; the Teams channel address should still stay internal |
