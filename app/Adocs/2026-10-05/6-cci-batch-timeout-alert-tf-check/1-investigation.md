# Investigation

| What was checked | Finding |
|---|---|
| Resource type | `dynatrace_log_alert`, not in the Dynatrace provider |
| Query | Log group `/aws/lambda/cci-fa-comm-calc`, text "Task timed out", DEBUG excluded, then sort and limit |
| Schedule | Every 5 minutes over the last 6 minutes, more than 0 results, once |
| Actions | PagerDuty with a hard-coded integration key, email to 6 recipients |
| Security | The integration key should not be in the repo |
