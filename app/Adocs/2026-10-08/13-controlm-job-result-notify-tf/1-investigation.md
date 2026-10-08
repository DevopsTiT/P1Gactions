# Investigation

| What was checked | Finding |
|---|---|
| Search | activejobs ended in 10 min, dedup per run, join abend from controlm_alert in 24 h, Japanese TITLE and BODY |
| Lookups | controlm_addresslist (Method), controlm_job_Definition, controlm_SpecificContact (Email) |
| Schedule | Every minute, Last 5 minutes |
| Throttle | `$result.JOB_CODE$`, 10 minutes |
| Action | Email To one person, CC per-job contact, Normal |
| First screenshot | Repeat of the jenkins_statistics search |
