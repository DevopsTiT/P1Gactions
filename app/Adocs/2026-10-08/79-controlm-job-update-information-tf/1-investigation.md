# Control-M Job Update Information Investigation

| What I checked | What I found |
|---|---|
| Sources | controlm_def_ver_jobs and controlm_def_ver_lnki_p, is_current_version=Y |
| Grouping | By job_id and table_id |
| Predecessor | From condition, pattern L-job-OK |
| Successor | Built by an append subsearch |
| Exclusion | pre_job not YC-D-001-F |
| Schedule | Every 30 minutes, last 60 minutes |
| Action | Email with CSV, priority Normal |
| Not visible | The end of the search |
| First screenshot | Same CHDR010M alert as seq 78 |
