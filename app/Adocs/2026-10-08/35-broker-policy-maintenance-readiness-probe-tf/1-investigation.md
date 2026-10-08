# Readiness Probe Investigation

| What I checked | What I found |
|---|---|
| Search | Newest 2 health lines, alert when the status code changed. |
| Window and cron | Last 5 minutes, every 5 minutes. |
| Action | Email only. |
| Field list in the search screenshot | No statusCode field on the sampled /meta/health lines. |
| Behaviour on recovery | Mails, because 503 to 200 is a change. |
| Behaviour while failing | Silent after the first mail, because 503 to 503 is no change. |
| Pods | Two pods share the index, so the newest 2 lines can come from different pods. |
