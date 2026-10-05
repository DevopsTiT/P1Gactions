# Investigation

| What was checked | Finding |
|---|---|
| Resource | `dynatrace_log_alert` "hpm_sharepoint_api_lambda_error", not a real resource |
| Query | Log group hpm-sharepoint-api-prod, `status == "ERROR"` or content contains "ERROR" |
| Schedule | Daily at 10:00 over the last 24 hours |
| Actions | Problem MEDIUM, throttle 60 minutes, email to naoya.sota, chungyueh.chiu, hiroshi.annaka |
| Sister alert | `cmx-sharepoint-api.tf` (seq 7), same team, hourly |
| Secrets | None |
