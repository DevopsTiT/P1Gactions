# Control-M Job Result Notify Fix Investigation

| What I checked | What I found |
|---|---|
| Address list lookup | `JobID as job_name OUTPUT Method`. Seq 13 matched on job_name. |
| Job definition lookup | Outputs mem_lib, cmd_line, memname, node_id and host. Seq 13 did not have it. |
| Contact lookup | Outputs Email, used as the email CC. |
| PrimarySupport | Falls back to "N/A" when 対応方法 is empty. |
| Schedule | Every minute, last 5 minutes, throttle on JOB_CODE for 10 minutes |
| Action | Email to one person, CC per-job contact, priority Normal |
