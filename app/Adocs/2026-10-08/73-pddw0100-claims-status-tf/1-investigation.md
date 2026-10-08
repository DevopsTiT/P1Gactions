# PDDW0100 Claims Status Investigation

| What I checked | What I found |
|---|---|
| Search | PDDW* active jobs, latest snapshot per odate and order_id, Ended OK only |
| Lookups | Average run info by job_name, claims job list by job_id |
| Schedule | 08:15 every day, last 24 hours, expires 1 hour |
| Action | Email, priority Highest, inline table |
| 10-07 seq 14 | Fired only if no PDDW job ended OK |
| 10-05 seq 31 | Report workflow, claims list keyed on job_name |
