# Claims ICM Investigation

| What I checked | What I found |
|---|---|
| Search | The jenkins_statistics template, the same as FCR, with `where application="Claims ICM"`. |
| Time range | Last 2 hours. |
| Cron | Every 3 minutes. |
| Expires | 24 hours. |
| Trigger | Results greater than 0, for each result, no throttle. |
| Actions | Only "Add to Triggered Alerts". |
