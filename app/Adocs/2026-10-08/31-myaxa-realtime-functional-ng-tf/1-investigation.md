# MyAXA Investigation

| What I checked | What I found |
|---|---|
| Search | The jenkins_statistics template, with `where application="MyAXA"`. |
| Time range | Last 2 hours. |
| Cron | Every minute. |
| Expires | 24 hours. |
| Trigger | Results greater than 0, for each result, no throttle. |
| Action | Alert Status Manager, Production email mode. |
| PagerDuty | Cut off in the screenshot. |
