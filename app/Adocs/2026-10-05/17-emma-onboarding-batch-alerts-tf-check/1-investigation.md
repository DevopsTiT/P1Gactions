# Investigation

| What was checked | Finding |
|---|---|
| Resources | 5 `dynatrace_log_alert` blocks, none real |
| Log group | All `/aws/lambda/myaxa-onboarding-batch-prod` |
| Matches | 4 precise `<function> :: <event>` strings, 1 broad "handleOnboardedCustomers" plus "error" |
| Trigger | Every 5 minutes, last 5 minutes, more than 0, once, no throttle |
| Actions | Email to 6 recipients, priority HIGH, subject `Alert: $name$` |
| Descriptions | All placeholder `"Optional"` |
| Secrets | None |
