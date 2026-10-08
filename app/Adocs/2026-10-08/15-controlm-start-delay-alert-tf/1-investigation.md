# Control-M Start Delay Investigation

| What I checked | What I found |
|---|---|
| Alert name | Control-M 遅延アラート (start time delay) |
| Base search | `sourcetype=controlm_alert "Start Time Delay"` |
| Joins | addresslist (JobID renamed to job_name), job_Definition, SpecificContact |
| current_time | `yyyyMMddHHmmss`; HH is Splunk substr position 9 |
| Schedule | cron */2, Last 5 minutes |
| Trigger | More than 0 results, For each result |
| Throttle | JOB_CODE, 5 minutes |
| Actions | Append to `controlmalertabendhistory2.csv`, send email |
| PagerDuty | Not used |
