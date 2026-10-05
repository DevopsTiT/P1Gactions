# Investigation

| What was checked | Finding |
|---|---|
| Resource | `dynatrace_log_alert` "hpm_survey_monkey_lambda_error", not a real resource |
| Query | Log group hpm-survey-monkey-prod, `status == "ERROR"` or content contains "ERROR" |
| Schedule | Hourly over the last 60 minutes, throttle 60 minutes |
| Actions | Problem MEDIUM, email to naoya.sota, chungyueh.chiu, hiroshi.annaka |
| Description | Typos "Lamda" and "Survey money" |
| Secrets | None |
