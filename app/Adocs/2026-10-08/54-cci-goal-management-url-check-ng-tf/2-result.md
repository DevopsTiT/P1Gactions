# CCI Goal Management Result

| Item | Value |
|---|---|
| Resource | cci_goal_management_url_check_ng |
| Logic | job_result per job, fails >= 2 and oks == 0 in 60 minutes |
| enabled | false until check query 1 confirms the jobs |
| Severity | high |
| PagerDuty | "0" |
