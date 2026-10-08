# Application Monitoring URL Investigation

| What I checked | What I found |
|---|---|
| Search | jenkins_console text logs with "[HTTP Monitor]". |
| Name | Console source path, cleaned. |
| Response code | `status`, renamed to responsecode. |
| Rule | Newest 2 runs per job, OK only when 200. |
| Window and cron | 15 minutes, every minute. |
| Action | Alert Status Manager, Production, PagerDuty Disable. |
