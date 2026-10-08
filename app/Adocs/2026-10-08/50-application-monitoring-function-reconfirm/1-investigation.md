# Function Reconfirm Investigation

| What I checked | What I found |
|---|---|
| Search | Same as seq 47. |
| Window | 120 minutes, cron */1. |
| Filter | pager_duty = "0". |
| Last line | `event > 0` is nearly always true; Alert Status Manager decides from status. |
| Sourcetype | json:jenkins:old on jenkins_statistics is not yet verified. |
