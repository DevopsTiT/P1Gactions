# Investigation

| What was checked | Finding |
|---|---|
| Resource type | `dynatrace_log_alert`, not in the provider |
| Query | Log group `/aws/lambda/cmx-sharepoint-api-prod`, text "Error" |
| Case | DQL `contains` is case-sensitive by default; Splunk is not |
| Schedule | Hourly, last 60 minutes, throttle 60 minutes |
| Actions | Dynatrace problem severity MEDIUM, email to 3 recipients |
| Secrets | None |
