# CHDE010M MyAXA UL Investigation

| What I checked | What I found |
|---|---|
| Search | controlm_temp, controlm_activejobs, job_name CHDE010M, dedup odate, yesterday only |
| odate format | Splunk parses it with `%y%m%d`, so it is 6 digits |
| Schedule | 11:30 Monday to Saturday, last 1 day |
| Action | Email, priority Normal, subject carries MSG |
| Earlier versions | 10-05 seq 30/31 (report, wrong odate format) and 10-07 seq 14 (merged no-success) |
