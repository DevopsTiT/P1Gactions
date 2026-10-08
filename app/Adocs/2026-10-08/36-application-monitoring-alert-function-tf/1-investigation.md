# Application Monitoring Function Investigation

| What I checked | What I found |
|---|---|
| Template | jenkins_statistics, the same base as the per-app alerts. |
| Result logic | Real Time results are emptied, so Functional results count. |
| Scope | `where pager_duty="0"`, so every non-paging app is covered. |
| Maintenance | Left join on build_url to jenkins_console "Application is in mantenance". |
| Window and cron | 120 minutes, every minute. |
| Action | Alert Status Manager, Production. |
