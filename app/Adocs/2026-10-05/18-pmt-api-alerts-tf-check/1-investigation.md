# Investigation

| What was checked | Finding |
|---|---|
| Resources | 9 `dynatrace_log_alert` blocks, none real |
| Log group | All `/aws/lambda/pmt-api-prod` |
| Alert 2 | `parse content, "LD LD LD LD NUMBER:memory_usage"` has no anchor, so the number is wrong |
| Alerts 6 and 7 | Same phrase, same schedule, same problem action |
| Throttle | 60 seconds on alerts 4, 6, 7, 8, 9, which is shorter than the 5-minute schedule |
| Alert 3 | 6-minute window on a 5-minute schedule |
| Subjects | `Alert: $name$` except alert 5 (Japanese subject) |
| Descriptions | `"Optional"` on 8 of 9 |
| Secrets | None |
