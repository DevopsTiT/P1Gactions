# Investigation

| What was checked | Finding |
|---|---|
| Resources | 2 `dynatrace_log_alert` blocks, not real |
| Log group, alert 1 | `/aws/lambda/recrutimp-serverless-prod` (missing "i") |
| Log group, alert 2 | `/aws/lambda/recruitimp-serverless-prod` |
| Alert 1 parse | `LD LD WORD:level`, no anchor text |
| Alert 2 parse | `WORD:session_id WORD:level WORD:user_id`, no SPACE, cannot match |
| Schedules | Alert 1 daily 08:00 over 24 hours; alert 2 every 5 minutes over 5 minutes |
| Recipients | Alert 1: etool_maintenance and chungyueh.chiu. Alert 2: etool_maintenance |
| Secrets | None |
