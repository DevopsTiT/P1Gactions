# CCI Goal Management URL Check Investigation

| What I checked | What I found |
|---|---|
| Base search | jenkins/test, job_result not ABORTED, job_name contains "Management". |
| Response code | JSON `status`, renamed to responsecode. |
| OK rule | Any 200 in the last 2 runs. |
| Schedule | cron */1, Last 24 hours. |
| Actions | Add to Triggered Alerts; Alert Status Manager, Production, PagerDuty Disable. |
